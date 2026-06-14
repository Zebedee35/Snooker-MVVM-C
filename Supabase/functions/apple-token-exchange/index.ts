// Supabase Edge Function: apple-token-exchange
// Deploy this function to Supabase Edge Functions
//
// Deploy command:
// supabase functions deploy apple-token-exchange --project-ref vlvrwvqgzdxfvotjueml
//
// Purpose:
// Sign in with Apple only returns the user's full name / email on the FIRST
// authorization. If the account is deleted without revoking Apple's token, the
// next sign-in returns neither (Apple still considers the app authorized). To
// fix that, account deletion must revoke the Apple token — which requires an
// Apple *refresh token*.
//
// This function runs right after a successful sign-in: the client sends the
// single-use `authorizationCode`, and we exchange it (using the Apple client
// secret) for a refresh token, then store it on the user's profile. The
// `delete-account` function later uses that refresh token to revoke access.
//
// Required secrets (Supabase Dashboard > Edge Functions > Secrets):
// - SUPABASE_URL                (provided automatically)
// - SUPABASE_ANON_KEY           (provided automatically)
// - SUPABASE_SERVICE_ROLE_KEY   (provided automatically)
// - APPLE_CLIENT_ID    For the native flow this is the app bundle id (coders35.Snooker)
// - APPLE_TEAM_ID      Apple Developer Team ID
// - APPLE_KEY_ID       Key ID of the "Sign in with Apple" .p8 key
// - APPLE_PRIVATE_KEY  Contents of the .p8 key (base64 encoded)
//
// Prerequisite: run 05_account_deletion_setup.sql to add
// user_profiles.apple_refresh_token.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// Build the Apple client secret (a short-lived ES256 JWT). Returns null when
// the Apple secrets are not configured.
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

    const { code } = await req.json();
    if (!code) {
      return new Response(JSON.stringify({ error: "Missing authorization code" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // Resolve the caller from their JWT.
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

    const clientId = Deno.env.get("APPLE_CLIENT_ID");
    const clientSecret = await makeAppleClientSecret();
    if (!clientId || !clientSecret) {
      // Not configured yet — nothing to do, but don't fail sign-in.
      console.log("Apple token exchange skipped: secrets not configured");
      return new Response(JSON.stringify({ success: true, stored: false }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Exchange the single-use authorization code for tokens.
    const body = new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      code,
      grant_type: "authorization_code",
    });

    const tokenResponse = await fetch("https://appleid.apple.com/auth/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: body.toString(),
    });

    if (!tokenResponse.ok) {
      const errorText = await tokenResponse.text();
      console.error(`Apple token exchange failed: ${tokenResponse.status} - ${errorText}`);
      return new Response(JSON.stringify({ error: "Token exchange failed" }), {
        status: 502,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const tokenData = await tokenResponse.json();
    const refreshToken = tokenData.refresh_token as string | undefined;
    if (!refreshToken) {
      console.log("Apple token exchange returned no refresh token");
      return new Response(JSON.stringify({ success: true, stored: false }), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Store the refresh token on the profile with the service role key so the
    // client never holds it.
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
    const { error: updateError } = await supabaseAdmin
      .from("user_profiles")
      .update({ apple_refresh_token: refreshToken })
      .eq("id", user.id);

    if (updateError) {
      console.error("Failed to store Apple refresh token:", updateError);
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    console.log(`Stored Apple refresh token for user ${user.id}`);
    return new Response(JSON.stringify({ success: true, stored: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("apple-token-exchange error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
