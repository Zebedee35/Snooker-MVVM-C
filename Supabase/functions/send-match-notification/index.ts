// Supabase Edge Function: send-match-notification
// Deploy this function to Supabase Edge Functions
//
// Deploy command:
// supabase functions deploy send-match-notification --project-ref vlvrwvqgzdxfvotjueml
//
// Required secrets (set in Supabase Dashboard > Edge Functions > Secrets):
// - APNS_KEY_ID: Your Apple Push Notification Key ID
// - APNS_TEAM_ID: Your Apple Developer Team ID
// - APNS_PRIVATE_KEY: Your .p8 file content (base64 encoded)
// - APNS_BUNDLE_ID: Your app's bundle ID (e.g., coders35.Snooker)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

// APNs Configuration
const APNS_HOST_PRODUCTION = "api.push.apple.com";
const APNS_HOST_SANDBOX = "api.sandbox.push.apple.com";
const APNS_HOST =
  Deno.env.get("APNS_ENVIRONMENT") === "production"
    ? APNS_HOST_PRODUCTION
    : APNS_HOST_SANDBOX;

interface MatchNotificationPayload {
  match_id: string;
  tournament_id: string;
  tournament_name: string;
  round: string;
  old_status: string;
  new_status: string;
  home_player: string;
  away_player: string;
  home_score: number | null;
  away_score: number | null;
}

interface APNsPayload {
  aps: {
    alert: {
      title: string;
      subtitle?: string;
      body: string;
    };
    sound: string;
    badge?: number;
    "mutable-content"?: number;
    "content-available"?: number;
  };
  match_id?: string;
  tournament_id?: string;
}

// Generate JWT token for APNs authentication
async function generateAPNsToken(): Promise<string> {
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const privateKeyBase64 = Deno.env.get("APNS_PRIVATE_KEY")!;

  // Decode base64 private key
  const privateKeyPem = atob(privateKeyBase64);

  // Import the private key
  const privateKey = await jose.importPKCS8(privateKeyPem, "ES256");

  // Create JWT
  const jwt = await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .sign(privateKey);

  return jwt;
}

// Send push notification to APNs
async function sendToAPNs(
  token: string,
  payload: APNsPayload,
  apnsToken: string
): Promise<{ success: boolean; error?: string }> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID") || "coders35.Snooker";

  try {
    const response = await fetch(`https://${APNS_HOST}/3/device/${token}`, {
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

    if (response.ok) {
      return { success: true };
    } else {
      const errorText = await response.text();
      console.error(
        `APNs error for token ${token}: ${response.status} - ${errorText}`
      );
      return { success: false, error: `${response.status}: ${errorText}` };
    }
  } catch (error) {
    console.error(`Failed to send to APNs: ${error}`);
    return { success: false, error: error.message };
  }
}

// Build notification content based on match status
function buildNotificationPayload(
  match: MatchNotificationPayload
): APNsPayload {
  let title: string;
  let body: string;
  let subtitle: string | undefined;

  const scoreText = `${match.home_score ?? 0} - ${match.away_score ?? 0}`;

  switch (match.new_status) {
    case "Break":
      title = "🔴 Match on Break";
      subtitle = match.tournament_name;
      body = `${match.home_player} ${scoreText} ${match.away_player}\n${match.round}`;
      break;

    case "Completed":
    case "Finished":
      // Determine winner
      const homeScore = match.home_score ?? 0;
      const awayScore = match.away_score ?? 0;
      const winner =
        homeScore > awayScore ? match.home_player : match.away_player;

      title = "🏆 Match Completed";
      subtitle = match.tournament_name;
      body = `${winner} wins!\n${match.home_player} ${scoreText} ${match.away_player}\n${match.round}`;
      break;

    default:
      title = "Match Update";
      subtitle = match.tournament_name;
      body = `${match.home_player} ${scoreText} ${match.away_player}`;
  }

  return {
    aps: {
      alert: {
        title,
        subtitle,
        body,
      },
      sound: "default",
      "mutable-content": 1,
    },
    match_id: match.match_id,
    tournament_id: match.tournament_id,
  };
}

serve(async (req) => {
  try {
    // Only accept POST requests
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    // Parse incoming payload
    const matchData: MatchNotificationPayload = await req.json();
    console.log("Received match notification request:", matchData);

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Get target device tokens based on notification settings
    const { data: tokens, error: tokensError } = await supabase.rpc(
      "get_notification_targets",
      {
        p_tournament_name: matchData.tournament_name,
        p_round_name: matchData.round,
      }
    );

    if (tokensError) {
      console.error("Error fetching tokens:", tokensError);
      return new Response(JSON.stringify({ error: tokensError.message }), {
        status: 500,
        headers: { "Content-Type": "application/json" },
      });
    }

    if (!tokens || tokens.length === 0) {
      console.log("No target tokens found");
      return new Response(JSON.stringify({ message: "No tokens to notify" }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    console.log(`Found ${tokens.length} tokens to notify`);

    // Generate APNs JWT token
    const apnsToken = await generateAPNsToken();

    // Build notification payload
    const notificationPayload = buildNotificationPayload(matchData);

    // Send notifications in parallel (batch of 100)
    let tokensSent = 0;
    let tokensFailed = 0;
    const batchSize = 100;

    for (let i = 0; i < tokens.length; i += batchSize) {
      const batch = tokens.slice(i, i + batchSize);

      const results = await Promise.all(
        batch.map((t: { token: string }) =>
          sendToAPNs(t.token, notificationPayload, apnsToken)
        )
      );

      results.forEach((result) => {
        if (result.success) {
          tokensSent++;
        } else {
          tokensFailed++;
        }
      });
    }

    // Log notification result
    await supabase.from("notification_logs").insert({
      match_id: matchData.match_id,
      tournament_id: matchData.tournament_id,
      old_status: matchData.old_status,
      new_status: matchData.new_status,
      tokens_sent: tokensSent,
      tokens_failed: tokensFailed,
    });

    console.log(`Notifications sent: ${tokensSent}, failed: ${tokensFailed}`);

    return new Response(
      JSON.stringify({
        success: true,
        tokens_sent: tokensSent,
        tokens_failed: tokensFailed,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Edge function error:", error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
