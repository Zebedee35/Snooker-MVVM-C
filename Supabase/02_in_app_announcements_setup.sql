-- ============================================================
-- In-App Announcements Setup for Snooker App
-- ============================================================
-- Run this script in Supabase SQL Editor
-- NOTE: This script drops and recreates announcements table + RPC.
-- ============================================================

-- 0) Reset existing objects (data will be removed)
DROP FUNCTION IF EXISTS get_active_announcements(TIMESTAMPTZ);
DROP TABLE IF EXISTS app_announcements CASCADE;
DROP FUNCTION IF EXISTS set_updated_at_app_announcements();

-- 1) Create table
CREATE TABLE app_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    announcement_kind TEXT NOT NULL CHECK (announcement_kind IN ('error', 'info', 'warning', 'success')),
    content VARCHAR(500) NOT NULL CHECK (char_length(trim(content)) BETWEEN 1 AND 500),
    expires_at TIMESTAMPTZ NULL,
    display_mode TEXT NOT NULL DEFAULT 'persistent' CHECK (display_mode IN ('one_time', 'persistent')),
    placement_zone TEXT NOT NULL DEFAULT 'bottom' CHECK (placement_zone IN ('top', 'bottom')),
    display_rank SMALLINT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2) Useful indexes
CREATE INDEX IF NOT EXISTS idx_app_announcements_active ON app_announcements(is_active);
CREATE INDEX IF NOT EXISTS idx_app_announcements_expiry ON app_announcements(expires_at);
CREATE INDEX IF NOT EXISTS idx_app_announcements_display_rank ON app_announcements(display_rank DESC, created_at DESC);

-- 3) Keep updated_at fresh
CREATE OR REPLACE FUNCTION set_updated_at_app_announcements()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_updated_at_app_announcements ON app_announcements;

CREATE TRIGGER trg_set_updated_at_app_announcements
BEFORE UPDATE ON app_announcements
FOR EACH ROW
EXECUTE FUNCTION set_updated_at_app_announcements();

-- 4) RLS
ALTER TABLE app_announcements ENABLE ROW LEVEL SECURITY;

-- Public app can only read active + not-expired rows
DROP POLICY IF EXISTS "Public read active announcements" ON app_announcements;
CREATE POLICY "Public read active announcements"
ON app_announcements
FOR SELECT
TO anon, authenticated
USING (
    is_active = TRUE
    AND (expires_at IS NULL OR expires_at > NOW())
);

-- Service role can fully manage rows
DROP POLICY IF EXISTS "Service role full manage announcements" ON app_announcements;
CREATE POLICY "Service role full manage announcements"
ON app_announcements
FOR ALL
TO service_role
USING (TRUE)
WITH CHECK (TRUE);

-- 5) RPC for mobile clients (already filtered + sorted)
CREATE OR REPLACE FUNCTION get_active_announcements(p_now TIMESTAMPTZ DEFAULT NOW())
RETURNS TABLE (
    id UUID,
    announcement_kind TEXT,
    content TEXT,
    expires_at TIMESTAMPTZ,
    display_mode TEXT,
    placement_zone TEXT,
    display_rank SMALLINT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
STABLE
AS $$
    SELECT
        a.id,
                a.announcement_kind,
        a.content,
        a.expires_at,
        a.display_mode,
                a.placement_zone,
                a.display_rank,
        a.is_active,
        a.created_at
    FROM app_announcements a
    WHERE a.is_active = TRUE
      AND (a.expires_at IS NULL OR a.expires_at > p_now)
        ORDER BY a.display_rank DESC, a.created_at DESC;
$$;

GRANT EXECUTE ON FUNCTION get_active_announcements(TIMESTAMPTZ) TO anon, authenticated;

-- 6) Example data
INSERT INTO app_announcements (announcement_kind, content, expires_at, display_mode, placement_zone, display_rank)
VALUES
    (
        'error',
        'Su anda LiveScore servisimizde gecici bir sikinti yasiyoruz. Duzeltmek icin tum cabamizi sarf ediyoruz.',
        NULL,
        'persistent',
        'top',
        100
    ),
    (
        'info',
        'Eger uygulamamizi begeniyorsaniz AYARLAR kismina gidip bize destek olabilirsiniz.',
        NULL,
        'one_time',
        'bottom',
        50
    ),
    (
        'warning',
        '2027 Sezonu Haziran ayinda yuklenecektir.',
        '2026-06-11T08:25:19+00:00',
        'one_time',
        'top',
        80
    )
ON CONFLICT DO NOTHING;

-- Quick check
-- SELECT * FROM get_active_announcements();
