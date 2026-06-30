-- Adds a user-editable, globally-unique nickname to user_profiles.
-- Run this once in the Supabase SQL editor (Dashboard → SQL Editor).
--
-- Uniqueness is enforced case-insensitively via a unique index on lower(nickname).
-- The app catches the 23505 violation and shows "This nickname is already taken."

ALTER TABLE public.user_profiles
    ADD COLUMN IF NOT EXISTS nickname text;

CREATE UNIQUE INDEX IF NOT EXISTS user_profiles_nickname_unique
    ON public.user_profiles (lower(nickname))
    WHERE nickname IS NOT NULL;

-- NOTE: This assumes user_profiles already has RLS letting a user UPDATE their
-- own row (id = auth.uid()). If not, add a policy such as:
--
--   CREATE POLICY "Users can update own profile"
--       ON public.user_profiles FOR UPDATE
--       USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
