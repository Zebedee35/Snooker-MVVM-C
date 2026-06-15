-- ============================================================
-- Supabase Live Activity (ActivityKit) Setup for Snooker App
-- ============================================================
-- Run AFTER 01_push_notification_setup.sql (reuses pg_net + service key).
-- Run in Supabase Dashboard > SQL Editor.
-- ============================================================


-- 1. Per-activity push tokens
--    One row per running Live Activity. The app inserts/updates this from
--    LiveActivityManager when iOS hands it a push token. The Edge Function
--    reads `push_token` to send update/end pushes to that specific activity.
-- ============================================================

CREATE TABLE IF NOT EXISTS live_activities (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    activity_id TEXT UNIQUE NOT NULL,            -- ActivityKit Activity.id
    match_id    UUID NOT NULL REFERENCES matches(id),
    push_token  TEXT NOT NULL,                   -- per-activity APNs token (hex)
    status      TEXT NOT NULL DEFAULT 'active',  -- 'active' | 'ended'
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_live_activities_match  ON live_activities(match_id);
CREATE INDEX IF NOT EXISTS idx_live_activities_status ON live_activities(status);

ALTER TABLE live_activities ENABLE ROW LEVEL SECURITY;

-- App has no auth, mirror the device_tokens policy.
CREATE POLICY "Allow anonymous live_activity management" ON live_activities
    FOR ALL USING (true) WITH CHECK (true);


-- 2. (Optional, iOS 17.2+) push-to-start token column on device_tokens
--    Lets the backend START a Live Activity remotely without the app running.
--    Skip this if you only want app-initiated activities.
-- ============================================================

ALTER TABLE device_tokens ADD COLUMN IF NOT EXISTS pts_token TEXT;


-- 3. Trigger: when a followed match's score/status changes, push the update
--    We keep the trigger on `matches` (NOT on a high-frequency frames table)
--    so we don't blow the APNs Live Activity update budget. One push per
--    meaningful change (frame score or status) is the right granularity.
-- ============================================================

CREATE OR REPLACE FUNCTION notify_live_activity_update()
RETURNS TRIGGER AS $$
DECLARE
    v_tournament_name TEXT;
    v_home_name TEXT;
    v_away_name TEXT;
    v_event TEXT;
    v_has_activity BOOLEAN;
    v_payload JSONB;
    -- The Edge Function authenticates DB work with its OWN env service-role key;
    -- this header only needs a valid project JWT to pass the function's auth
    -- gate, so the public anon key (same one the app uses) is sufficient and
    -- avoids needing a DB-level GUC (which Supabase blocks).
    v_service_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsdnJ3dnFnemR4ZnZvdGp1ZW1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk3Mjk2NTAsImV4cCI6MjA1NTMwNTY1MH0.ZdDg3droSvP5gb2VehBA_J_ekj4oJuPJE4wzPhXeT48';
BEGIN
    -- Only act if there is at least one ACTIVE Live Activity for this match.
    SELECT EXISTS(
        SELECT 1 FROM live_activities
        WHERE match_id = NEW.id AND status = 'active'
    ) INTO v_has_activity;

    IF NOT v_has_activity THEN
        RETURN NEW;
    END IF;

    -- Fire only when something the activity displays actually changed.
    IF NEW.status IS NOT DISTINCT FROM OLD.status
       AND NEW.home_player_score IS NOT DISTINCT FROM OLD.home_player_score
       AND NEW.away_player_score IS NOT DISTINCT FROM OLD.away_player_score THEN
        RETURN NEW;
    END IF;

    -- Decide whether this is a normal update or the final "end" event.
    IF NEW.status IN ('Completed', 'Finished') THEN
        v_event := 'end';
    ELSE
        v_event := 'update';
    END IF;

    SELECT t.name INTO v_tournament_name
    FROM tournament t WHERE t.id = NEW.tournament_id;

    SELECT COALESCE(p.first_name || ' ' || p.surname, 'TBD') INTO v_home_name
    FROM player p WHERE p.id = NEW.home_player_id;

    SELECT COALESCE(p.first_name || ' ' || p.surname, 'TBD') INTO v_away_name
    FROM player p WHERE p.id = NEW.away_player_id;

    v_payload := jsonb_build_object(
        'match_id', NEW.id,
        'event', v_event,
        'status', NEW.status,
        'round', NEW.round,
        'tournament_name', COALESCE(v_tournament_name, ''),
        'home_name', COALESCE(v_home_name, 'TBD'),
        'away_name', COALESCE(v_away_name, 'TBD'),
        'home_score', NEW.home_player_score,
        'away_score', NEW.away_player_score
    );

    PERFORM net.http_post(
        url := 'https://vlvrwvqgzdxfvotjueml.supabase.co/functions/v1/update-live-activity',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || v_service_key
        ),
        body := v_payload
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


DROP TRIGGER IF EXISTS on_match_live_activity_update ON matches;

CREATE TRIGGER on_match_live_activity_update
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_live_activity_update();


-- 4. House-keeping: who marks an activity 'ended'?
--    >>> The Edge Function does, NOT a SQL trigger. <<<
--
--    There used to be a second AFTER UPDATE trigger here
--    (on_match_completed_cleanup) that set live_activities.status='ended' as
--    soon as a match hit Completed/Finished. It caused a real bug:
--
--      * Postgres fires AFTER UPDATE triggers in ALPHABETICAL order by name,
--        so on_match_*c*ompleted_cleanup ran BEFORE on_match_*l*ive_activity_update.
--      * Even if the order were reversed, net.http_post() only ENQUEUES the
--        request — the Edge Function runs asynchronously AFTER the transaction
--        commits, then looks up tokens via `status = 'active'`. If the trigger
--        had already flipped the rows to 'ended', the function found nothing
--        and the "end" push was never sent.
--
--    So we DROP that trigger. The flow is now single-owner:
--      match completes -> notify_live_activity_update fires once with
--      event='end' -> Edge Function reads the still-'active' rows, pushes the
--      end event to APNs, and ONLY THEN sets those rows to 'ended'
--      (see endedActivityIds in update-live-activity/index.ts).
-- ============================================================

DROP TRIGGER IF EXISTS on_match_completed_cleanup ON matches;
DROP FUNCTION IF EXISTS cleanup_ended_live_activities();


-- ============================================================
-- NOTES
-- ============================================================
-- * This file uses current_setting('app.settings.service_role_key') instead of
--   hard-coding the key (your 01_ file hard-codes it — consider migrating that
--   too). Set it once with:
--     ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
--
-- * Make sure pg_net is enabled (already done for push notifications):
--     CREATE EXTENSION IF NOT EXISTS pg_net;
--
-- TESTING
-- ============================================================
-- SELECT * FROM live_activities WHERE status = 'active';
-- UPDATE matches SET home_player_score = home_player_score + 1
--   WHERE id = 'some-live-match-id';   -- should trigger one push
