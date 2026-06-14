//
//  AuthManager.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 14.06.2026.
//

import UIKit
import Supabase

// MARK: - Auth Manager

/// Wraps Supabase Auth and keeps the user's profile (name + email) and
/// preferences (notification / dark mode / hide TBD) in sync with the cloud.
///
/// Everything is keyed by `auth.uid()` so the same account follows the user
/// across devices and lays the groundwork for future prediction competitions.
final class AuthManager {

    static let shared = AuthManager()

    private init() {}

    // MARK: - Cached Identity

    private(set) var userId: String?
    private(set) var displayName: String?
    private(set) var email: String?

    var isSignedIn: Bool { userId != nil }

    private enum DefaultsKey {
        static let name = "auth_user_name"
        static let email = "auth_user_email"
        static let notificationSetting = "notification_setting"
        static let darkMode = "dark_mode"
        static let hideTBD = "hide_tbd"
    }

    // MARK: - Session Restore

    /// Restores any persisted session on launch and re-applies cloud settings.
    func restoreSession() async {
        do {
            let session = try await SupabaseAPI.client.auth.session
            handleSession(session)
            await pullCloudSettings()
        } catch {
            // No valid session — user is simply signed out.
            print("[AuthManager] No session to restore: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign In

    /// Completes a Sign in with Apple handshake against Supabase, then upserts
    /// the profile and reconciles local/cloud settings.
    func signInWithApple(idToken: String, nonce: String, fullName: String?, email: String?, authorizationCode: String?) async throws {
        let session = try await SupabaseAPI.client.auth.signInWithIdToken(
            credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
        )
        handleSession(session, overrideName: fullName, overrideEmail: email)

        await upsertProfile()
        await reconcileSettingsOnSignIn()

        // Store an Apple refresh token so the account can be revoked on deletion.
        // Only available on the first authorization, so we never overwrite an
        // existing token with nothing.
        if let authorizationCode {
            await exchangeAndStoreAppleToken(authorizationCode: authorizationCode)
        }

        PushNotificationManager.shared.linkDeviceToUser(userId: userId)
    }

    // MARK: - Sign Out

    func signOut() async {
        PushNotificationManager.shared.linkDeviceToUser(userId: nil)

        do {
            try await SupabaseAPI.client.auth.signOut()
        } catch {
            print("[AuthManager] Sign out failed: \(error.localizedDescription)")
        }

        userId = nil
        displayName = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.name)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.email)

        notifyAuthStateChanged()
    }

    // MARK: - Delete Account

    /// Permanently deletes the signed-in user's account.
    ///
    /// The anon-key client cannot remove an auth user, so this calls the
    /// `delete-account` Edge Function (authenticated with the user's JWT). The
    /// function uses the service role key to `auth.admin.deleteUser(uid)` — the
    /// `ON DELETE CASCADE` foreign keys then drop the `user_profiles` /
    /// `user_settings` rows — and best-effort revokes the Apple token.
    ///
    /// Once the server confirms deletion we sign out locally so the app returns
    /// to a signed-out state. Throws if the user is not signed in or the
    /// function call fails (so the UI can keep the account and show an error).
    func deleteAccount() async throws {
        guard isSignedIn else { throw AuthError.notSignedIn }

        // Unlink the device first so a deleted account leaves no dangling token.
        PushNotificationManager.shared.linkDeviceToUser(userId: nil)

        try await SupabaseAPI.client.functions.invoke("delete-account")

        // Server-side deletion succeeded — tear down the local session.
        do {
            try await SupabaseAPI.client.auth.signOut()
        } catch {
            // The auth user is already gone; a failed sign-out just means the
            // local token is stale. Clear local state regardless.
            print("[AuthManager] Sign out after deletion failed: \(error.localizedDescription)")
        }

        userId = nil
        displayName = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.name)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.email)

        notifyAuthStateChanged()
    }

    /// Sends the Apple `authorizationCode` to the `apple-token-exchange` Edge
    /// Function, which swaps it for a refresh token (using the Apple client
    /// secret) and stores it on the user's profile. Best effort — failures here
    /// must never break sign-in; they only mean Apple revocation won't run on
    /// account deletion.
    private func exchangeAndStoreAppleToken(authorizationCode: String) async {
        do {
            try await SupabaseAPI.client.functions.invoke(
                "apple-token-exchange",
                options: .init(body: AppleCodeExchangeRequest(code: authorizationCode))
            )
        } catch {
            print("[AuthManager] Apple token exchange failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Settings Sync

    /// Pushes the latest local preferences to the cloud (no-op when signed out).
    func syncSettingsToCloud(notification: String, darkMode: Bool, hideTBD: Bool, autoRounds: [String]) {
        guard isSignedIn else { return }
        Task {
            await pushSettings(notification: notification, darkMode: darkMode, hideTBD: hideTBD, autoRounds: autoRounds)
        }
    }

    // MARK: - Private: Session Handling

    private func handleSession(_ session: Session, overrideName: String? = nil, overrideEmail: String? = nil) {
        let user = session.user
        userId = user.id.uuidString

        if let overrideEmail, !overrideEmail.isEmpty {
            email = overrideEmail
        } else if let userEmail = user.email {
            email = userEmail
        } else {
            email = UserDefaults.standard.string(forKey: DefaultsKey.email)
        }

        // Apple only returns the name on the first sign-in, so fall back to the
        // cached value on subsequent sessions.
        if let overrideName, !overrideName.isEmpty {
            displayName = overrideName
        } else {
            displayName = UserDefaults.standard.string(forKey: DefaultsKey.name)
        }

        UserDefaults.standard.set(displayName, forKey: DefaultsKey.name)
        UserDefaults.standard.set(email, forKey: DefaultsKey.email)

        notifyAuthStateChanged()
    }

    // MARK: - Private: Profile

    private func upsertProfile() async {
        guard let userId else { return }
        let row = ProfileRow(id: userId, fullName: displayName, email: email)
        do {
            try await SupabaseAPI.client
                .from("user_profiles")
                .upsert(row, onConflict: "id")
                .execute()
        } catch {
            print("[AuthManager] Profile upsert failed: \(error)")
        }
    }

    // MARK: - Private: Settings Reconciliation

    /// On sign-in: if the account already has cloud settings, pull and apply
    /// them (cloud wins); otherwise seed the cloud with the local settings.
    private func reconcileSettingsOnSignIn() async {
        if let cloud = await fetchCloudSettings() {
            applyCloudSettings(cloud)
        } else {
            let local = currentLocalSettings()
            await pushSettings(notification: local.notification, darkMode: local.darkMode, hideTBD: local.hideTBD, autoRounds: local.autoRounds)
        }
    }

    private func pullCloudSettings() async {
        guard let cloud = await fetchCloudSettings() else { return }
        applyCloudSettings(cloud)
    }

    private func fetchCloudSettings() async -> SettingsResponse? {
        guard let userId else { return nil }
        do {
            let rows: [SettingsResponse] = try await SupabaseAPI.client
                .from("user_settings")
                .select()
                .eq("user_id", value: userId)
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("[AuthManager] Fetch cloud settings failed: \(error)")
            return nil
        }
    }

    private func pushSettings(notification: String, darkMode: Bool, hideTBD: Bool, autoRounds: [String]) async {
        guard let userId else { return }
        let row = SettingsUpsertRow(
            userId: userId,
            notificationSetting: notification,
            darkMode: darkMode,
            hideTbd: hideTBD,
            laAutoRounds: autoRounds
        )
        do {
            try await SupabaseAPI.client
                .from("user_settings")
                .upsert(row, onConflict: "user_id")
                .execute()
        } catch {
            print("[AuthManager] Push settings failed: \(error)")
        }
    }

    private func applyCloudSettings(_ settings: SettingsResponse) {
        UserDefaults.standard.set(settings.notificationSetting, forKey: DefaultsKey.notificationSetting)
        if let dark = settings.darkMode {
            UserDefaults.standard.set(dark, forKey: DefaultsKey.darkMode)
        }
        if let hide = settings.hideTbd {
            UserDefaults.standard.set(hide, forKey: DefaultsKey.hideTBD)
        }

        if let setting = NotificationSetting(rawValue: settings.notificationSetting) {
            PushNotificationManager.shared.updateNotificationSetting(setting)
        }

        // Restore the auto-follow round selection and mirror it to THIS device's
        // backend row so push-to-start targets the right matches.
        if let rounds = settings.laAutoRounds {
            LiveActivityAutoRounds.selected = Set(rounds.compactMap { MatchRoundCategory(rawValue: $0) })
            PushNotificationManager.shared.updateLiveActivityAutoRounds(LiveActivityAutoRounds.selectedRawValues)
        }

        DispatchQueue.main.async {
            if let dark = settings.darkMode {
                self.applyDarkMode(dark)
            }
            if let hide = settings.hideTbd {
                NotificationCenter.default.post(
                    name: .hideTBDMatchesChanged,
                    object: nil,
                    userInfo: ["isHidden": hide]
                )
            }
            if settings.laAutoRounds != nil {
                NotificationCenter.default.post(name: .liveActivityAutoRoundsChanged, object: nil)
            }
            // Let the Settings screen rebuild its rows to reflect synced values.
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
        }
    }

    private func currentLocalSettings() -> (notification: String, darkMode: Bool, hideTBD: Bool, autoRounds: [String]) {
        let notification = UserDefaults.standard.string(forKey: DefaultsKey.notificationSetting)
            ?? NotificationSetting.allResults.rawValue
        let darkMode = UserDefaults.standard.bool(forKey: DefaultsKey.darkMode)
        let hideTBD = UserDefaults.standard.bool(forKey: DefaultsKey.hideTBD)
        let autoRounds = LiveActivityAutoRounds.selectedRawValues
        return (notification, darkMode, hideTBD, autoRounds)
    }

    private func applyDarkMode(_ isDark: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }

    private func notifyAuthStateChanged() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
        }
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "You are not signed in."
        }
    }
}

// MARK: - Row Models

private struct AppleCodeExchangeRequest: Encodable {
    let code: String
}

private struct ProfileRow: Encodable {
    let id: String
    let fullName: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
    }
}

private struct SettingsUpsertRow: Encodable {
    let userId: String
    let notificationSetting: String
    let darkMode: Bool
    let hideTbd: Bool
    let laAutoRounds: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case notificationSetting = "notification_setting"
        case darkMode = "dark_mode"
        case hideTbd = "hide_tbd"
        case laAutoRounds = "la_auto_rounds"
    }
}

/// Decoded with the shared client's `convertFromSnakeCase` strategy, so the
/// snake_case columns map onto these camelCase properties automatically.
private struct SettingsResponse: Decodable {
    let notificationSetting: String
    let darkMode: Bool?
    let hideTbd: Bool?
    let laAutoRounds: [String]?
}

// MARK: - Notification Names

extension Notification.Name {
    static let authStateChanged = Notification.Name("authStateChanged")
}
