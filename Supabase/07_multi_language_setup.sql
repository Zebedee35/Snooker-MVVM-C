-- 07_multi_language_setup.sql
--
-- Adds the app-language preference to user_settings so a signed-in user's
-- choice follows them across devices, alongside dark mode and the other
-- preferences already synced there.
--
-- Safe to re-run.

-- The value is either a BCP-47 language code the app ships ("en", "tr",
-- "zh-Hans") or the literal 'system', meaning "follow the device".
--
-- Deliberately a plain text column rather than an enum: the app negotiates an
-- unknown or withdrawn code back to a supported one at read time, so shipping
-- a new language must not require a migration here.
alter table public.user_settings
  add column if not exists language text not null default 'system';

comment on column public.user_settings.language is
  'App language: a BCP-47 code the app ships, or ''system'' to follow the device.';

-- Rows written before this column existed already get 'system' from the
-- default, which is the same behaviour they had. Nothing to backfill.
