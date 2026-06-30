// Supabase Edge Function: start-live-activity
//
// Remotely STARTS a Live Activity (push-to-start, iOS 17.2+) on every device
// that opted into a match's round category. Invoked by the DB trigger
// `notify_live_activity_start` (see 06_live_activity_auto_start_setup.sql) when
// a Final / Semi / Quarter match enters a live state.
//
// After the activity starts on the device, the app registers its per-activity
// push token in `live_activities`, and the existing `update-live-activity`
// function handles score updates / end.
//
// Deploy:
//   supabase functions deploy start-live-activity --project-ref vlvrwvqgzdxfvotjueml
//
// Required secrets (same as update-live-activity):
//   APNS_KEY_ID, APNS_TEAM_ID, APNS_PRIVATE_KEY (base64 .p8), APNS_BUNDLE_ID
//   APNS_ENVIRONMENT = "sandbox" | "production"  (optional; defaults to auto-try)

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import * as jose from "https://deno.land/x/jose@v4.14.4/index.ts";

const APNS_HOST_PRODUCTION = "api.push.apple.com";
const APNS_HOST_SANDBOX = "api.sandbox.push.apple.com";

// MUST match the Swift ActivityAttributes struct name exactly.
const ATTRIBUTES_TYPE = "MatchLiveActivityAttributes";

interface StartPayload {
  match_id: string;
  round: string;
  round_category: string; // 'final' | 'semiFinal' | 'quarterFinal'
  status: string;
  tournament_name: string;
  home_name: string;
  away_name: string;
  home_score: number | null;
  away_score: number | null;
}

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

// Best-of frames needed to win, by round. Mirrors framesToWin(for:) in Swift.
function framesToWin(round: string): number {
  const r = round.toLowerCase();
  if (r.includes("final") && !r.includes("semi") && !r.includes("quarter")) return 10;
  if (r.includes("semi")) return 6;
  if (r.includes("quarter")) return 5;
  return 4;
}

// Build the push-to-start body. `attributes` are the static fields the Widget
// declares; `content-state` is the dynamic part. Keys MUST match the Swift
// MatchLiveActivityAttributes / ContentState property names exactly.
function buildStartPayload(p: StartPayload) {
  const nowSeconds = Math.floor(Date.now() / 1000);

  return {
    aps: {
      timestamp: nowSeconds,
      event: "start",
      "content-state": {
        homeScore: p.home_score ?? 0,
        awayScore: p.away_score ?? 0,
        status: p.status,
        round: p.round,
        currentBreak: null,
        atTable: null,
      },
      "attributes-type": ATTRIBUTES_TYPE,
      attributes: {
        matchId: p.match_id,
        tournamentName: p.tournament_name,
        homeName: p.home_name,
        homeFlag: "",
        awayName: p.away_name,
        awayFlag: "",
        framesToWin: framesToWin(p.round),
      },
      alert: {
        title: "Match starting",
        body: `${p.home_name} vs ${p.away_name} — ${p.round}`,
      },
      "stale-date": nowSeconds + 30 * 60,
    },
  };
}

async function sendToAPNs(
  ptsToken: string,
  body: unknown,
  apnsToken: string,
): Promise<{ success: boolean; status?: number; error?: string }> {
  const bundleId = Deno.env.get("APNS_BUNDLE_ID") || "coders35.Snooker";
  const topic = `${bundleId}.push-type.liveactivity`;
  const envPref = Deno.env.get("APNS_ENVIRONMENT");
  const hosts = envPref === "sandbox"
    ? [APNS_HOST_SANDBOX]
    : envPref === "production"
    ? [APNS_HOST_PRODUCTION]
    : [APNS_HOST_PRODUCTION, APNS_HOST_SANDBOX];

  let last = { success: false, status: 0, error: "no attempt" };
  for (const host of hosts) {
    try {
      const res = await fetch(`https://${host}/3/device/${ptsToken}`, {
        method: "POST",
        headers: {
          authorization: `bearer ${apnsToken}`,
          "apns-topic": topic,
          "apns-push-type": "liveactivity",
          "apns-priority": "10",
          "content-type": "application/json",
        },
        body: JSON.stringify(body),
      });
      if (res.ok) return { success: true, status: res.status };
      const text = await res.text();
      last = { success: false, status: res.status, error: text };
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

    const payload: StartPayload = await req.json();
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    // Devices that opted into this round category and can be push-started.
    //
    // PostgREST caps every response at `max_rows` (1000 by default), so a single
    // select silently truncates to the first 1000 devices. Page through with
    // .range() (ordered by the unique `token` for stable paging) so EVERY
    // opted-in device is push-started, no matter how many there are.
    const PAGE_SIZE = 1000;
    const devices: { pts_token: string }[] = [];
    let from = 0;

    while (true) {
      const { data: page, error } = await supabase
        .from("device_tokens")
        .select("pts_token")
        .not("pts_token", "is", null)
        .contains("la_auto_rounds", [payload.round_category])
        .order("token", { ascending: true })
        .range(from, from + PAGE_SIZE - 1);

      if (error) {
        return new Response(JSON.stringify({ error: error.message }), { status: 500 });
      }
      if (!page || page.length === 0) break;
      devices.push(...page);
      if (page.length < PAGE_SIZE) break; // last page
      from += PAGE_SIZE;
    }

    if (devices.length === 0) {
      return new Response(JSON.stringify({ message: "no opted-in devices" }), { status: 200 });
    }

    const apnsToken = await generateAPNsToken();
    const body = buildStartPayload(payload);

    let started = 0, failed = 0;
    await Promise.all(
      devices.map(async (d: { pts_token: string }) => {
        const r = await sendToAPNs(d.pts_token, body, apnsToken);
        if (r.success) {
          started++;
        } else {
          failed++;
          console.error(`push-to-start fail (${r.status}): ${r.error}`);
        }
      }),
    );

    console.log(`start-live-activity: started ${started}, failed ${failed} for match ${payload.match_id}`);
    return new Response(JSON.stringify({ started, failed }), { status: 200 });
  } catch (e) {
    console.error("start-live-activity error:", e);
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
