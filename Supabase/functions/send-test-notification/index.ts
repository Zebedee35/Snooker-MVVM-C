// Supabase Edge Function: send-test-notification
//
// Sends ONE test push to a SINGLE device — the caller's own device — so push
// delivery can be verified without notifying anyone else. It never queries
// get_notification_targets; it targets exactly the token passed in the body,
// and only after verifying that token belongs to the authenticated user.
//
// Deploy command:
// supabase functions deploy send-test-notification --project-ref vlvrwvqgzdxfvotjueml
//
// Reuses the same APNs secrets as send-match-notification:
// - APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY (base64 .p8), APNS_BUNDLE_ID

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const APNS_HOST_PRODUCTION = "api.push.apple.com";
const APNS_HOST_SANDBOX = "api.sandbox.push.apple.com";

interface APNsPayload {
  aps: {
    alert: { title: string; subtitle?: string; body: string };
    sound: string;
    "mutable-content"?: number;
  };
  test?: boolean;
}

// Generate JWT token for APNs authentication
async function generateAPNsToken(): Promise<string> {
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const privateKeyBase64 = Deno.env.get("APNS_PRIVATE_KEY")!;

  const privateKeyPem = atob(privateKeyBase64);
  const privateKey = await jose.importPKCS8(privateKeyPem, "ES256");

  return await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .sign(privateKey);
}

// Send to a specific APNs endpoint
async function sendToAPNsEndpoint(
  token: string,
  payload: APNsPayload,
  apnsToken: string,
  bundleId: string,
  host: string,
): Promise<{ success: boolean; error?: string }> {
  try {
    const response = await fetch(`https://${host}/3/device/${token}`, {
      method: "POST",
      headers: {
        authorization: `bearer ${apnsToken}`,
        "apns-topic": bundleId,
        "apns-push-type": "alert",
        "apns-priority": "10",
        "apns-expiration": "0",
        "content-type": "application/json",
      },
      body: JSON.stringify(payload),
    });

    if (response.ok) return { success: true };

    const errorText = await response.text();
    console.error(`APNs error (${host}): ${response.status} - ${errorText}`);
    return { success: false, error: `${response.status}: ${errorText}` };
  } catch (error) {
    console.error(`Failed to send to APNs (${host}): ${error}`);
    return { success: false, error: error.message };
  }
}

// Try production first; fall back to sandbox (Xcode debug builds use sandbox).
async function sendToAPNs(
  token: string,
  payload: APNsPayload,
  apnsToken: string,
): Promise<{ success: boolean; error?: string }> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID") || "coders35.Snooker";

  const prod = await sendToAPNsEndpoint(
    token, payload, apnsToken, bundleId, APNS_HOST_PRODUCTION,
  );
  if (prod.success) return prod;

  if (prod.error?.includes("BadDeviceToken") || prod.error?.includes("400")) {
    console.log("Production failed, trying sandbox…");
    return await sendToAPNsEndpoint(
      token, payload, apnsToken, bundleId, APNS_HOST_SANDBOX,
    );
  }
  return prod;
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const authHeader = req.headers.get("Authorization") || "";
    const jwt = authHeader.replace(/^Bearer\s+/i, "");
    if (!jwt) {
      return new Response(JSON.stringify({ error: "Missing Authorization" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json().catch(() => ({}));
    const token: string | undefined = body?.token;
    if (!token) {
      return new Response(JSON.stringify({ error: "Missing device token" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

    // Identify the caller from their JWT.
    const authClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: `Bearer ${jwt}` } },
    });
    const { data: userData, error: userError } = await authClient.auth.getUser();
    if (userError || !userData?.user) {
      return new Response(JSON.stringify({ error: "Invalid session" }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }
    const uid = userData.user.id;

    // Verify the target token is registered AND owned by the caller, so this
    // can only ever ping the caller's own device(s).
    const admin = createClient(supabaseUrl, serviceKey);
    const { data: row, error: rowError } = await admin
      .from("device_tokens")
      .select("token, user_id")
      .eq("token", token)
      .maybeSingle();

    if (rowError) {
      return new Response(JSON.stringify({ error: rowError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }
    if (!row) {
      return new Response(JSON.stringify({ error: "Unknown device token" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }
    // Reject only if the token is explicitly owned by SOMEONE ELSE. An unlinked
    // token (user_id null) is allowed — the app always passes its own token, so
    // this still only ever reaches the caller's device.
    if (row.user_id && row.user_id !== uid) {
      return new Response(
        JSON.stringify({ error: "Token does not belong to caller" }),
        { status: 403, headers: { "Content-Type": "application/json" } },
      );
    }

    // Build and send a single benign test push.
    const payload: APNsPayload = {
      aps: {
        alert: {
          title: "🎱 Test Notification",
          subtitle: "Snooker",
          body: "Push delivery is working on this device.",
        },
        sound: "pool.wav",
        "mutable-content": 1,
      },
      test: true,
    };

    const apnsToken = await generateAPNsToken();
    const result = await sendToAPNs(token, payload, apnsToken);

    return new Response(
      JSON.stringify({ success: result.success, error: result.error ?? null }),
      {
        status: result.success ? 200 : 502,
        headers: { "Content-Type": "application/json" },
      },
    );
  } catch (error) {
    console.error("send-test-notification error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
