-- ============================================================
-- Supabase Account Deletion Setup for Snooker App
-- ============================================================
-- Apple's App Store guidelines require any app offering account
-- creation / Sign in with Apple to also offer in-app account
-- deletion. The client calls the `delete-account` Edge Function
-- (authenticated with the user's JWT); the function uses the
-- service role key to delete the auth user.
--
-- The user_profiles / user_settings tables defined in
-- 04_sign_in_with_apple_setup.sql already declare
--   REFERENCES auth.users(id) ON DELETE CASCADE
-- so deleting the auth user automatically removes those rows.
-- No additional schema is required for basic deletion.
--
-- This file only adds the OPTIONAL column used for Apple token
-- revocation. Run it in the Supabase SQL Editor if you intend to
-- store and revoke Apple refresh tokens.
-- ============================================================


-- Optional: store the Apple refresh token so the delete-account
-- Edge Function can revoke the user's Apple token on deletion.
-- ============================================================
-- Leave this column empty / skip this file if you are not yet
-- capturing Apple refresh tokens at sign-in. Account deletion
-- works without it; revocation is simply skipped.

ALTER TABLE user_profiles
    ADD COLUMN IF NOT EXISTS apple_refresh_token TEXT;
