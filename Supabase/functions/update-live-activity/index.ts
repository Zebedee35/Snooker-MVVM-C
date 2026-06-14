// Supabase Edge Function: update-live-activity
//
// Pushes ActivityKit Live Activity updates/ends to APNs.
// Reuses the SAME APNs .p8 key / JWT signing as send-match-notification — the
// only differences vs. a normal alert push are the apns-topic suffix, the
// apns-push-type header, and the JSON body shape (aps.event + content-state).
//
// Deploy:
//   supabase functions deploy update-live-activity --project-ref vlvrwvqgzdxfvotjueml
//
// Required secrets (same ones you already set for send-match-notification):
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY (base64 .p8), APNS_BUNDLE_ID
//   APNS_ENVIRONMENT = "sandbox" | "production"   (optional, defaults to auto-try)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const APNS_HOST_PRODUCTION = "api.push.apple.com";
const APNS_HOST_SANDBOX = "api.sandbox.push.apple.com";

interface UpdatePayload {
  match_id: string;
  event: "update" | "end";
  status: string;
  round: string;
  tournament_name: string;
  home_name: string;
  away_name: string;
  home_score: number | null;
  away_score: number | null;
}

// --- APNs JWT (identical to send-match-notification) ---
async function generateAPNsToken(): Promise<string> {
  const keyId = Deno.env.get("APNS_KEY_ID")!;
  const teamId = Deno.env.get("APNS_TEAM_ID")!;
  const privateKeyPem = atob(Deno.env.get("APNS_PRIVATE_KEY")!);
  const privateKey = await jose.importPKCS8(privateKeyPem, "ES256");
  return await new jose.SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: keyId })
    .setIssuer(teamId)
    .setIssuedAt()
    .sign(privateKey);
}

// Build the Live Activity push body.
// ⚠️ content-state keys MUST match MatchLiveActivityAttributes.ContentState
//    property names in Swift (homeScore, awayScore, status, round, currentBreak, atTable).
function buildLiveActivityPayload(p: UpdatePayload) {
  const nowSeconds = Math.floor(Date.now() / 1000);

  const contentState: Record<string, unknown> = {
    homeScore: p.home_score ?? 0,
    awayScore: p.away_score ?? 0,
    status: p.status,
    round: p.round,
    currentBreak: null,
    atTable: null,
  };

  const aps: Record<string, unknown> = {
    timestamp: nowSeconds,
    event: p.event, // "update" | "end"
    "content-state": contentState,
    // After this, iOS dims the activity if no fresher push arrives (30 min).
    "stale-date": nowSeconds + 30 * 60,
  };

  if (p.event === "end") {
    // Keep the final score on the Lock Screen for an hour, then auto-dismiss.
    aps["dismissal-date"] = nowSeconds + 60 * 60;
  }

  // Optional: surface a key moment as an alert (frame won, match decided).
  // Comment out to keep updates silent (recommended for frequent score ticks).
  // aps["alert"] = { title: "Frame!", body: `${p.home_name} ${p.home_score}-${p.away_score} ${p.away_name}` };

  return { aps };
}

async function sendToAPNs(
  token: string,
  body: unknown,
  apnsToken: string,
  priority: string,
): Promise<{ success: boolean; status?: number; error?: string }> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID") || "coders35.Snooker";
  const topic = `${bundleId}.push-type.liveactivity`; // ⬅️ the Live Activity topic
  const envPref = Deno.env.get("APNS_ENVIRONMENT");
  const hosts = envPref === "sandbox"
    ? [APNS_HOST_SANDBOX]
    : envPref === "production"
    ? [APNS_HOST_PRODUCTION]
    : [APNS_HOST_PRODUCTION, APNS_HOST_SANDBOX]; // auto: try prod then sandbox

  let last = { success: false, status: 0, error: "no attempt" };
  for (const host of hosts) {
    try {
      const res = await fetch(`https://${host}/3/device/${token}`, {
        method: "POST",
        headers: {
          authorization: `bearer ${apnsToken}`,
          "apns-topic": topic,
          "apns-push-type": "liveactivity", // ⬅️ NOT "alert"
          "apns-priority": priority, // "10" key moments, "5" minor ticks
          "content-type": "application/json",
        },
        body: JSON.stringify(body),
      });
      if (res.ok) return { success: true, status: res.status };
      const text = await res.text();
      last = { success: false, status: res.status, error: text };
      // BadDeviceToken on prod -> retry sandbox; otherwise stop.
      if (!text.includes("BadDeviceToken") && res.status !== 400) break;
    } catch (e) {
      last = { success: false, status: 0, error: String(e) };
    }
  }
  return last;
}

serve(async (req) => {
  try {
    if (req.method !== "POST") return new Response("Method not allowed", { status: 405 });

    const payload: UpdatePayload = await req.json();
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // All active activities for this match.
    const { data: activities, error } = await supabase
      .from("live_activities")
      .select("activity_id, push_token")
      .eq("match_id", payload.match_id)
      .eq("status", "active");

    if (error) {
      return new Response(JSON.stringify({ error: error.message }), { status: 500 });
    }
    if (!activities || activities.length === 0) {
      return new Response(JSON.stringify({ message: "no active activities" }), { status: 200 });
    }

    const apnsToken = await generateAPNsToken();
    const body = buildLiveActivityPayload(payload);
    // Key moments (frame won / match ended) get high priority; routine ticks 5.
    const priority = payload.event === "end" ? "10" : "5";

    let sent = 0, failed = 0;
    const endedActivityIds: string[] = [];

    await Promise.all(
      activities.map(async (a) => {
        const r = await sendToAPNs(a.push_token, body, apnsToken, priority);
        if (r.success) {
          sent++;
          if (payload.event === "end") endedActivityIds.push(a.activity_id);
        } else {
          failed++;
          // 410 Gone / BadDeviceToken => the activity is dead, stop targeting it.
          if (r.status === 410 || r.error?.includes("BadDeviceToken")) {
            endedActivityIds.push(a.activity_id);
          }
          console.error(`APNs fail (${r.status}): ${r.error}`);
        }
      }),
    );

    if (endedActivityIds.length > 0) {
      await supabase
        .from("live_activities")
        .update({ status: "ended" })
        .in("activity_id", endedActivityIds);
    }

    return new Response(JSON.stringify({ sent, failed, event: payload.event }), { status: 200 });
  } catch (e) {
    console.error("update-live-activity error:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
