# Account Deletion — Setup Guide

Apple's App Store Review Guidelines (§5.1.1(v)) require that any app supporting
account creation — including Sign in with Apple — also lets users **delete their
account** from within the app.

The iOS app exposes this as a destructive **Delete Account** row in
**Settings → ACCOUNT** (shown only when signed in). It calls the
`delete-account` Supabase Edge Function with the user's JWT, which removes the
auth user with the service role key, then signs out locally.

Bundle identifier: `coders35.Snooker`

---

## How it works

1. **Settings → Delete Account** shows a confirmation alert.
2. On confirm, `AuthManager.deleteAccount()` invokes the `delete-account` Edge
   Function (the Supabase client attaches the user's JWT automatically).
3. The function resolves the caller from their JWT, best-effort revokes the
   Apple token, then calls `auth.admin.deleteUser(uid)` with the service role
   key.
4. `ON DELETE CASCADE` on `user_profiles` / `user_settings`
   (see [`04_sign_in_with_apple_setup.sql`](04_sign_in_with_apple_setup.sql))
   removes those rows. `device_tokens.user_id` is `ON DELETE SET NULL`, so the
   device token simply unlinks.
5. The client signs out locally and returns to the signed-out state.

## 1. Database (optional)

Basic deletion needs **no** schema changes — the cascade FKs already exist.

Only if you plan to enable Apple token revocation, run
[`05_account_deletion_setup.sql`](05_account_deletion_setup.sql) to add the
optional `user_profiles.apple_refresh_token` column.

## 2. Deploy the Edge Function

```bash
supabase functions deploy delete-account --project-ref vlvrwvqgzdxfvotjueml
```

`SUPABASE_URL`, `SUPABASE_ANON_KEY` and `SUPABASE_SERVICE_ROLE_KEY` are injected
automatically — no extra secrets are required for basic deletion.

## 3. Apple token revocation (recommended by Apple)

Sign in with Apple only returns the user's name / email on the **first**
authorization. If an account is deleted without revoking Apple's token, the next
sign-in returns neither (Apple still considers the app authorized). To avoid
that, deletion revokes the Apple token. This needs an Apple **refresh token**,
which the app obtains and stores at sign-in time.

The client + functions are already wired up:

- The iOS app captures the Apple `authorizationCode` at sign-in and POSTs it to
  the **`apple-token-exchange`** Edge Function.
- `apple-token-exchange` swaps the code for a refresh token and stores it in
  `user_profiles.apple_refresh_token` (service role).
- `delete-account` reads that refresh token and POSTs to
  `https://appleid.apple.com/auth/revoke` before deleting the user.

Every step is **best effort** — if the Apple secrets are missing the exchange /
revoke are skipped and sign-in & deletion still work.

### To turn it on

1. Run [`05_account_deletion_setup.sql`](05_account_deletion_setup.sql) to add
   `user_profiles.apple_refresh_token`.
2. In the **Apple Developer Portal**, create a **Sign in with Apple** key
   (Certificates, Identifiers & Profiles → Keys → **+** → enable *Sign in with
   Apple*), download the `.p8`, and note the **Key ID** and **Team ID**.
3. Set these Edge Function secrets
   (**Dashboard → Edge Functions → Secrets**, or via CLI below):

   | Secret | Value |
   | --- | --- |
   | `APPLE_CLIENT_ID` | `coders35.Snooker` (bundle id for the native flow) |
   | `APPLE_TEAM_ID` | Apple Developer Team ID |
   | `APPLE_KEY_ID` | Key ID of the Sign in with Apple `.p8` key |
   | `APPLE_PRIVATE_KEY` | `.p8` key contents, **base64 encoded** |

   ```bash
   # base64-encode the .p8 (single line)
   base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n' | pbcopy

   supabase secrets set \
     APPLE_CLIENT_ID=coders35.Snooker \
     APPLE_TEAM_ID=YOUR_TEAM_ID \
     APPLE_KEY_ID=YOUR_KEY_ID \
     APPLE_PRIVATE_KEY="$(pbpaste)" \
     --project-ref vlvrwvqgzdxfvotjueml
   ```

> Re-testing note: because the previous account was deleted *without* revocation,
> Apple still has the app authorized. To get the first-time prompt (and name)
> back once, remove it manually on the device: **Settings → [Apple ID] →
> Sign-In & Security → Sign in with Apple → Snooker → Stop Using Apple ID**.
> After revocation is live, deletion handles this automatically.

## 4. Verify

1. Sign in with Apple in the app.
2. Go to **Settings → Delete Account → Delete Account**.
3. Confirm the account row disappears from `user_profiles` / `user_settings`
   and the user is removed under **Authentication → Users** in the dashboard.
4. The app returns to the signed-out **Sign in with Apple** state.
