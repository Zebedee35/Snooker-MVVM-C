-- ============================================================
-- Supabase Push Notification Setup for Snooker App
-- ============================================================
-- Run these SQL commands in your Supabase SQL Editor
-- ============================================================

-- 1. Create device_tokens table to store APNs tokens
-- ============================================================

CREATE TABLE IF NOT EXISTS device_tokens (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    token TEXT UNIQUE NOT NULL,
    platform TEXT NOT NULL DEFAULT 'ios', -- 'ios' or 'android'
    notification_setting TEXT NOT NULL DEFAULT 'all_results',
    -- notification_setting options:
    -- 'all_results' - All match results
    -- 'main_events' - Main events only
    -- 'finals_only' - Only finals of main events
    -- 'none' - No notifications
    app_version TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for faster queries
CREATE INDEX IF NOT EXISTS idx_device_tokens_setting ON device_tokens(notification_setting);
CREATE INDEX IF NOT EXISTS idx_device_tokens_platform ON device_tokens(platform);

-- Enable RLS
ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

-- Allow anonymous inserts/updates (for app without auth)
CREATE POLICY "Allow anonymous token management" ON device_tokens
    FOR ALL
    USING (true)
    WITH CHECK (true);


-- 2. Create notification_logs table for tracking sent notifications
-- ============================================================

CREATE TABLE IF NOT EXISTS notification_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    match_id UUID REFERENCES matches(id),
    tournament_id UUID,
    old_status TEXT,
    new_status TEXT,
    tokens_sent INTEGER DEFAULT 0,
    tokens_failed INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for analytics
CREATE INDEX IF NOT EXISTS idx_notification_logs_match ON notification_logs(match_id);
CREATE INDEX IF NOT EXISTS idx_notification_logs_created ON notification_logs(created_at);


-- 3. Create main_tournaments table to define main events
-- ============================================================

CREATE TABLE IF NOT EXISTS main_tournaments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    tournament_name TEXT NOT NULL,
    -- Partial match için ILIKE kullanılacak
    -- Örn: '%World Championship%', '%UK Championship%', '%Masters%'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert some main tournaments
INSERT INTO main_tournaments (tournament_name) VALUES 
    ('%World Championship%'),
    ('%UK Championship%'),
    ('%Masters%'),
    ('%Tour Championship%'),
    ('%Champion of Champions%'),
    ('%World Grand Prix%'),
    ('%Players Championship%'),
    ('%British Open%'),
    ('%European Masters%'),
    ('%German Masters%'),
    ('%Welsh Open%'),
    ('%Northern Ireland Open%'),
    ('%Scottish Open%'),
    ('%English Open%'),
    ('%International Championship%'),
    ('%China Open%'),
    ('%Shanghai Masters%')
ON CONFLICT DO NOTHING;


-- 4. Create helper function to check if tournament is a main event
-- ============================================================

CREATE OR REPLACE FUNCTION is_main_tournament(tournament_name_param TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM main_tournaments 
        WHERE tournament_name_param ILIKE tournament_name
    );
END;
$$ LANGUAGE plpgsql;


-- 5. Create helper function to check if match is a final
-- ============================================================

CREATE OR REPLACE FUNCTION is_final_round(round_name TEXT)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN round_name ILIKE '%Final%' 
       AND round_name NOT ILIKE '%Semi%' 
       AND round_name NOT ILIKE '%Quarter%';
END;
$$ LANGUAGE plpgsql;


-- 6. Create function to get target device tokens based on settings
-- ============================================================

CREATE OR REPLACE FUNCTION get_notification_targets(
    p_tournament_name TEXT,
    p_round_name TEXT
)
RETURNS TABLE(token TEXT) AS $$
DECLARE
    v_is_main BOOLEAN;
    v_is_final BOOLEAN;
BEGIN
    v_is_main := is_main_tournament(p_tournament_name);
    v_is_final := is_final_round(p_round_name);
    
    RETURN QUERY
    SELECT dt.token FROM device_tokens dt
    WHERE dt.notification_setting != 'none'
      AND (
          -- all_results: everyone gets all notifications
          dt.notification_setting = 'all_results'
          OR
          -- main_events: only main tournament notifications
          (dt.notification_setting = 'main_events' AND v_is_main)
          OR
          -- finals_only: only finals of main tournaments
          (dt.notification_setting = 'finals_only' AND v_is_main AND v_is_final)
      );
END;
$$ LANGUAGE plpgsql;


-- 7. Create trigger function for match status changes
-- ============================================================

CCREATE OR REPLACE FUNCTION notify_match_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_tournament_name TEXT;
    v_home_player_name TEXT;
    v_away_player_name TEXT;
    v_payload JSONB;
    v_service_key TEXT := 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZsdnJ3dnFnemR4ZnZvdGp1ZW1sIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczOTcyOTY1MCwiZXhwIjoyMDU1MzA1NjUwfQ.LkYeYAJ1Dxe-kVU8WZnNh0YVYUtwazQdjGRcydfUIOo';
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status 
       AND NEW.status IN ('Break', 'Completed', 'Finished') THEN
        
        SELECT t.name INTO v_tournament_name
        FROM tournament t
        WHERE t.id = NEW.tournament_id;
        
        SELECT COALESCE(p.first_name || ' ' || p.surname, 'TBD') INTO v_home_player_name
        FROM player p
        WHERE p.id = NEW.home_player_id;
        
        SELECT COALESCE(p.first_name || ' ' || p.surname, 'TBD') INTO v_away_player_name
        FROM player p
        WHERE p.id = NEW.away_player_id;
        
        v_home_player_name := COALESCE(v_home_player_name, 'TBD');
        v_away_player_name := COALESCE(v_away_player_name, 'TBD');
        
        v_payload := jsonb_build_object(
            'match_id', NEW.id,
            'tournament_id', NEW.tournament_id,
            'tournament_name', v_tournament_name,
            'round', NEW.round,
            'old_status', OLD.status,
            'new_status', NEW.status,
            'home_player', v_home_player_name,
            'away_player', v_away_player_name,
            'home_score', NEW.home_player_score,
            'away_score', NEW.away_player_score
        );
        
        PERFORM net.http_post(
            url := 'https://vlvrwvqgzdxfvotjueml.supabase.co/functions/v1/send-match-notification',
            headers := jsonb_build_object(
                'Content-Type', 'application/json',
                'Authorization', 'Bearer ' || v_service_key
            ),
            body := v_payload
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- 8. Create the trigger on matches table
-- ============================================================

DROP TRIGGER IF EXISTS on_match_status_change ON matches;

CREATE TRIGGER on_match_status_change
    AFTER UPDATE ON matches
    FOR EACH ROW
    EXECUTE FUNCTION notify_match_status_change();


-- 9. Enable pg_net extension (required for HTTP calls from triggers)
-- ============================================================
-- Note: You may need to enable this from Supabase Dashboard > Extensions

CREATE EXTENSION IF NOT EXISTS pg_net;


-- 10. Set service role key as app setting (for trigger to use)
-- ============================================================
-- Replace YOUR_SERVICE_ROLE_KEY with your actual service role key
-- You can find this in Supabase Dashboard > Settings > API > service_role key

-- ALTER DATABASE postgres SET app.settings.service_role_key = 'YOUR_SERVICE_ROLE_KEY';


-- ============================================================
-- TESTING
-- ============================================================

-- Test: Check device tokens
-- SELECT * FROM device_tokens;

-- Test: Check if a tournament is main
-- SELECT is_main_tournament('World Championship 2025');

-- Test: Get notification targets for a match
-- SELECT * FROM get_notification_targets('World Championship 2025', 'Final');

-- Test: Simulate a status change (be careful in production!)
-- UPDATE matches SET status = 'Completed' WHERE id = 'some-match-id';
