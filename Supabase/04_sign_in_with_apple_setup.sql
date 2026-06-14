-- ============================================================
-- Supabase Sign in with Apple Setup for Snooker App
-- ============================================================
-- Run these SQL commands in your Supabase SQL Editor.
-- Prerequisite: Enable the Apple provider under
--   Authentication > Providers > Apple
-- and add the app bundle identifier (coders35.Snooker) to
-- "Authorized Client IDs". For native iOS the Services ID /
-- Secret Key can be left empty.
-- ============================================================


-- 0. Shared helper: keep updated_at fresh on every UPDATE
-- ============================================================

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 1. user_profiles: the minimal info the user shares (name + email)
-- ============================================================
-- The profile row is keyed by auth.users.id (auth.uid()). Apple
-- only returns full name / email on the FIRST sign-in, so the iOS
-- client upserts this row right after a successful sign-in.

CREATE TABLE IF NOT EXISTS user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Each user can only see and manage their own profile row.
DROP POLICY IF EXISTS "Users manage own profile" ON user_profiles;
CREATE POLICY "Users manage own profile" ON user_profiles
    FOR ALL
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

DROP TRIGGER IF EXISTS set_user_profiles_updated_at ON user_profiles;
CREATE TRIGGER set_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();


-- 2. user_settings: per-user preferences synced across devices
-- ============================================================

CREATE TABLE IF NOT EXISTS user_settings (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_setting TEXT NOT NULL DEFAULT 'all_results',
    -- notification_setting options:
    -- 'all_results' | 'main_events' | 'finals_only' | 'none'
    dark_mode BOOLEAN,
    hide_tbd BOOLEAN,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own settings" ON user_settings;
CREATE POLICY "Users manage own settings" ON user_settings
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP TRIGGER IF EXISTS set_user_settings_updated_at ON user_settings;
CREATE TRIGGER set_user_settings_updated_at
    BEFORE UPDATE ON user_settings
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at();


-- 3. Link device tokens to a signed-in user (optional)
-- ============================================================
-- Push registration stays anonymous; when a user signs in, the app
-- stamps the current device token row with their user_id so the
-- notification preference can follow the account across devices.

ALTER TABLE device_tokens
    ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens(user_id);

-- The existing "Allow anonymous token management" policy already
-- permits the app to update its own token row, so no new policy is
-- required here.


-- ============================================================
-- TESTING
-- ============================================================

-- Test: list profiles / settings (run as service role)
-- SELECT * FROM user_profiles;
-- SELECT * FROM user_settings;
-- SELECT token, user_id FROM device_tokens WHERE user_id IS NOT NULL;
