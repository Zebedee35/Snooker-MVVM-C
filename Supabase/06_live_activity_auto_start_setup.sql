-- ============================================================
-- Supabase Live Activity AUTO-START (push-to-start) Setup
-- ============================================================
-- Run AFTER 03_live_activity_setup.sql.
-- Enables the backend to START a Live Activity on a user's device with no app
-- interaction when a match enters a live state, for the rounds the user opted
-- into (Settings -> Auto Lock Screen). Requires iOS 17.2+ on the device
-- (push-to-start token). The existing 03_ trigger then handles score updates.
-- Run in Supabase Dashboard > SQL Editor.
-- ============================================================


-- 1. Per-device opt-in: which round categories to auto-start.
--    Written by the app (PushNotificationManager) as a text[] of category
--    raw values: 'final' | 'semiFinal' | 'quarterFinal'.
-- ============================================================

ALTER TABLE device_tokens
    ADD COLUMN IF NOT EXISTS la_auto_rounds TEXT[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS idx_device_tokens_la_auto_rounds
    ON device_tokens USING GIN (la_auto_rounds);


-- 1b. Per-account opt-in mirror: the same selection stored on user_settings so
--     it follows the user's Apple ID across devices. On sign-in the app pulls
--     this and re-applies it to the local store + this device's device_tokens.
-- ============================================================

ALTER TABLE user_settings
    ADD COLUMN IF NOT EXISTS la_auto_rounds TEXT[] NOT NULL DEFAULT '{}';


-- 2. Classify a raw round string into the app's category.
--    Mirrors MatchRoundCategory.category(for:) in Swift (order matters:
--    "Semi Final" / "Quarter Final" both contain "final").
-- ============================================================

CREATE OR REPLACE FUNCTION live_activity_round_category(p_round TEXT)
RETURNS TEXT AS $$
DECLARE
    r TEXT := lower(COALESCE(p_round, ''));
BEGIN
    IF r LIKE '%semi%' THEN
        RETURN 'semiFinal';
    ELSIF r LIKE '%quarter%' THEN
        RETURN 'quarterFinal';
    ELSIF r LIKE '%final%' THEN
        RETURN 'final';
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- 3. Trigger: when a match ENTERS a live state, push-to-start activities for
--    every device that opted into this match's round category.
--    Live states mirror the app: 'Live' and 'Break'.
-- ============================================================

CREATE OR REPLACE FUNCTION notify_live_activity_start()
RETURNS TRIGGER AS $$
DECLARE
    v_category TEXT;
    v_tournament_name TEXT;
    v_home_name TEXT;
    v_away_name TEXT;
    v_has_target BOOLEAN;
    v_payload JSONB;
    v_service_key TEXT := current_setting('app.settings.service_role_key', true);
    v_live_states TEXT[] := ARRAY['Live', 'Break'];
BEGIN
    -- Only on the transition INTO a live state (not on every score tick).
    IF NEW.status IS NULL OR NOT (NEW.status = ANY (v_live_states)) THEN
        RETURN NEW;
    END IF;
    IF OLD.status IS NOT NULL AND OLD.status = ANY (v_live_states) THEN
        RETURN NEW;  -- was already live
    END IF;

    v_category := live_activity_round_category(NEW.round);
    IF v_category IS NULL THEN
        RETURN NEW;  -- not a Final / Semi / Quarter
    END IF;

    -- Skip the HTTP call entirely if nobody opted into this category.
    SELECT EXISTS(
        SELECT 1 FROM device_tokens
        WHERE pts_token IS NOT NULL
          AND v_category = ANY (la_auto_rounds)
    ) INTO v_has_target;

    IF NOT v_has_target THEN
        RETURN NEW;
    END IF;

    SELECT t.name INTO v_tournament_name
    FROM tournament t WHERE t.id = NEW.tournament_id;

    SELECT COALESCE(p.first_name || ' ' || p.surname, 'TBD') INTO v_home_name
    FROM player p WHERE p.id = NEW.home_player_id;

    SELECT COALESCE(p.first_name || ' ' || p.surname, 'TBD') INTO v_away_name
    FROM player p WHERE p.id = NEW.away_player_id;

    v_payload := jsonb_build_object(
        'match_id', NEW.id,
        'round', NEW.round,
        'round_category', v_category,
        'status', NEW.status,
        'tournament_name', COALESCE(v_tournament_name, ''),
        'home_name', COALESCE(v_home_name, 'TBD'),
        'away_name', COALESCE(v_away_name, 'TBD'),
        'home_score', NEW.home_player_score,
        'away_score', NEW.away_player_score
    );

    PERFORM net.http_post(
        url := 'https://vlvrwvqgzdxfvotjueml.supabase.co/functions/v1/start-live-activity',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || v_service_key
        ),
        body := v_payload
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


DROP TRIGGER IF EXISTS on_match_live_activity_start ON matches;

CREATE TRIGGER on_match_live_activity_start
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_live_activity_start();


-- ============================================================
-- NOTES
-- ============================================================
-- * Requires app.settings.service_role_key + pg_net, same as 03_ (already set):
--     ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';
--     CREATE EXTENSION IF NOT EXISTS pg_net;
--
-- * The device must be iOS 17.2+ and have sent a pts_token (push-to-start).
--   On 16.2-17.1 auto-start only happens while the app is open (handled in-app).
--
-- TESTING
-- ============================================================
-- 1. Ensure a device row has: pts_token set AND la_auto_rounds @> ARRAY['final'].
--    SELECT token, pts_token, la_auto_rounds FROM device_tokens WHERE pts_token IS NOT NULL;
-- 2. Move a Final match into a live state to fire the start push:
--    UPDATE matches SET status = 'Live' WHERE id = 'some-final-match-id';
