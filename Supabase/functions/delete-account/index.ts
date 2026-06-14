// Supabase Edge Function: delete-account
// Deploy this function to Supabase Edge Functions
//
// Deploy command:
// supabase functions deploy delete-account --project-ref vlvrwvqgzdxfvotjueml
//
// Purpose:
// Apple's App Store guidelines require any app that offers account creation /
// Sign in with Apple to also offer in-app account deletion. The mobile client
// cannot delete an auth user with the anon key, so it calls this function with
// the signed-in user's JWT. The function:
//   1. Resolves the caller's user id from their JWT (anon client).
//   2. Best-effort revokes the user's Apple token (only when configured).
//   3. Deletes the auth user with the service role key. The ON DELETE CASCADE
//      foreign keys on user_profiles / user_settings drop those rows; the
//      device_tokens.user_id FK is ON DELETE SET NULL so the token simply
//      unlinks.
//
// Required secrets (Supabase Dashboard > Edge Functions > Secrets):
// - SUPABASE_URL                (provided automatically)
// - SUPABASE_ANON_KEY           (provided automatically)
// - SUPABASE_SERVICE_ROLE_KEY   (provided automatically)
//
// Optional secrets to enable Apple token revocation:
// - APPLE_CLIENT_ID    Services ID / bundle id registered with Apple (e.g. coders35.Snooker)
// - APPLE_TEAM_ID      Apple Developer Team ID
// - APPLE_KEY_ID       Key ID of the "Sign in with Apple" .p8 key
// - APPLE_PRIVATE_KEY  Contents of the .p8 key (base64 encoded)
// Revocation also requires an Apple refresh token stored for the user
// (user_profiles.apple_refresh_token). When any of these are missing the
// revocation step is skipped and account deletion still proceeds.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Build the Apple client secret (a short-lived ES256 JWT) used to authenticate
// against Apple's token endpoints. Returns null when secrets are not configured.
async function makeAppleClientSecret(): Promise<string | null> {
  const clientId = Deno.env.get("APPLE_CLIENT_ID");
  const teamId = Deno.env.get("APPLE_TEAM_ID");
  const keyId = Deno.env.get("APPLE_KEY_ID");
  const privateKeyBase64 = Deno.env.get("APPLE_PRIVATE_KEY");

  if (!clientId || !teamId || !keyId || !privateKeyBase64) {
    return null;
  }

  const privateKeyPem = atob(privateKeyBase64);
  const privateKey = await jose.importPKCS8(privateKeyPem, "ES256");

  const now = Math.floor(Date.now() / 1000);
  return await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt(now)
    .setExpirationTime(now + 300)
    .setAudience("https://appleid.apple.com")
    .setSubject(clientId)
    .sign(privateKey);
}

// Best-effort revocation of the user's Apple token. Never throws — a failure
// here must not block account deletion.
async function revokeAppleToken(
  supabaseAdmin: ReturnType<typeof createClient>,
  userId: string,
): Promise<void> {
  try {
    const clientId = Deno.env.get("APPLE_CLIENT_ID");
    const clientSecret = await makeAppleClientSecret();
    if (!clientId || !clientSecret) {
      console.log("Apple revocation skipped: secrets not configured");
      return;
    }

    // The refresh token must have been stored at sign-in time.
    const { data: profile, error } = await supabaseAdmin
      .from("user_profiles")
      .select("apple_refresh_token")
      .eq("id", userId)
      .maybeSingle();

    if (error) {
      console.log("Apple revocation skipped: could not read profile", error.message);
      return;
    }

    const refreshToken = profile?.apple_refresh_token as string | null | undefined;
    if (!refreshToken) {
      console.log("Apple revocation skipped: no stored refresh token");
      return;
    }

    const body = new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      token: refreshToken,
      token_type_hint: "refresh_token",
    });

    const response = await fetch("https://appleid.apple.com/auth/revoke", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    });

    if (response.ok) {
      console.log("Apple token revoked");
    } else {
      console.log(
        `Apple revocation failed: ${response.status} - ${await response.text()}`,
      );
    }
  } catch (error) {
    console.log(`Apple revocation error: ${error.message}`);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", {
        status: 405,
        headers: corsHeaders,
      });
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Resolve the caller from their JWT using the anon client.
    const supabaseAuth = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const {
      data: { user },
      error: userError,
    } = await supabaseAuth.auth.getUser();

    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Invalid session" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userId = user.id;
    console.log(`Deleting account for user ${userId}`);

    // Service-role client performs the privileged deletion.
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);

    // Optional Apple token revocation (best effort, before the row is gone).
    await revokeAppleToken(supabaseAdmin, userId);

    // Explicitly drop owned rows in case cascade FKs are ever missing; this is
    // idempotent and harmless when the cascade already handles them.
    await supabaseAdmin.from("user_settings").delete().eq("user_id", userId);
    await supabaseAdmin.from("user_profiles").delete().eq("id", userId);

    // Delete the auth user. Cascading FKs clean up anything left.
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(
      userId,
    );

    if (deleteError) {
      console.error("Failed to delete auth user:", deleteError);
      return new Response(JSON.stringify({ error: deleteError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`Account deleted for user ${userId}`);

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("delete-account error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
