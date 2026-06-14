# Sign in with Apple — Setup Guide

This document covers the **manual** steps required to enable Sign in with Apple
for the Snooker app. The iOS code and SQL are already in the repo; these steps
configure Apple and Supabase so they work together.

Bundle identifier: `coders35.Snooker`

---

## 1. Apple Developer Portal

1. Go to <https://developer.apple.com/account/resources/identifiers>.
2. Open the App ID for `coders35.Snooker`.
3. Enable the **Sign in with Apple** capability and save.

## 2. Xcode

1. Open `Snooker.xcodeproj`.
2. Select the **Snooker** target → **Signing & Capabilities**.
3. Click **+ Capability** and add **Sign in with Apple**.
   - The entitlements file (`Snooker/Snooker.entitlements`) already contains the
     `com.apple.developer.applesignin` key, but adding the capability lets Xcode
     refresh the provisioning profile.
4. Make sure automatic signing succeeds (provisioning profile now includes the
   Sign in with Apple entitlement).

## 3. Supabase Dashboard

1. Go to **Authentication → Providers → Apple**.
2. Toggle **Enable Sign in with Apple**.
3. In **Authorized Client IDs**, add the bundle identifier: `coders35.Snooker`.
   - For a native iOS-only flow you do **not** need a Services ID, Team ID, Key ID
     or Secret Key — those are only required for the web OAuth flow.
4. Save.

## 4. Database

1. Open **SQL Editor** in the Supabase dashboard.
2. Run the contents of [`04_sign_in_with_apple_setup.sql`](04_sign_in_with_apple_setup.sql).
3. Verify the new objects exist:
   - Tables `user_profiles` and `user_settings`.
   - Column `device_tokens.user_id`.

---

## How the flow works

1. User taps **Sign in with Apple** in Settings.
2. The app generates a random nonce, sends `sha256(nonce)` to Apple, and receives
   an identity token (plus name/email on the first sign-in only).
3. The app calls `supabase.auth.signInWithIdToken(provider: .apple, idToken:, nonce:)`.
   Supabase verifies the token against the Authorized Client ID and returns a
   session with a stable `auth.uid()`.
4. The app upserts the profile (`user_profiles`) and the user's preferences
   (`user_settings`), and stamps the current `device_tokens` row with `user_id`.
5. On the next launch the session is restored and cloud settings are re-applied.

## Notes / future work

- **Account deletion**: Apple requires apps that offer Sign in with Apple to also
  provide an in-app account deletion path. Add this before App Store submission.
- **Prediction competitions**: a future `predictions` table can reuse the same
  `auth.uid()` + RLS pattern established here.
