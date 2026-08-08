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
    private(set) var nickname: String?

    var isSignedIn: Bool { userId != nil }

    private enum DefaultsKey {
        static let name = "auth_user_name"
        static let email = "auth_user_email"
        static let nickname = "auth_user_nickname"
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
            // Recover the display name / nickname from the cloud in case this
            // install never received them from Apple (it only hands the name
            // over on the very first authorization).
            await loadCloudProfile()
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

        // Resolve the name from (in order) this sign-in's Apple payload, the
        // cloud profile, then the local cache — and load the saved nickname.
        await loadCloudProfile(appleName: fullName)
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
        nickname = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.name)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.email)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.nickname)

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
        nickname = nil
        UserDefaults.standard.removeObject(forKey: DefaultsKey.name)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.email)
        UserDefaults.standard.removeObject(forKey: DefaultsKey.nickname)

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

    /// Pushes whatever is currently stored locally, for callers that changed a
    /// single preference and shouldn't have to restate the rest.
    func syncCurrentSettingsToCloud() {
        guard isSignedIn else { return }
        let local = currentLocalSettings()
        Task {
            await pushSettings(
                notification: local.notification,
                darkMode: local.darkMode,
                hideTBD: local.hideTBD,
                autoRounds: local.autoRounds,
                language: local.language
            )
        }
    }

    /// Pushes the latest local preferences to the cloud (no-op when signed out).
    func syncSettingsToCloud(notification: String, darkMode: Bool, hideTBD: Bool, autoRounds: [String], language: String) {
        guard isSignedIn else { return }
        Task {
            await pushSettings(notification: notification, darkMode: darkMode, hideTBD: hideTBD, autoRounds: autoRounds, language: language)
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

        nickname = UserDefaults.standard.string(forKey: DefaultsKey.nickname)

        persistIdentity()
        notifyAuthStateChanged()
    }

    /// Caches the current identity to `UserDefaults` so it survives app
    /// relaunches (but not a delete + reinstall, which is why we also keep a
    /// copy in the cloud `user_profiles` row).
    private func persistIdentity() {
        UserDefaults.standard.set(displayName, forKey: DefaultsKey.name)
        UserDefaults.standard.set(email, forKey: DefaultsKey.email)
        UserDefaults.standard.set(nickname, forKey: DefaultsKey.nickname)
    }

    // MARK: - Public: Profile Editing

    /// Persists user-edited profile fields. An empty value leaves the existing
    /// stored value untouched. The nickname must be globally unique — a
    /// collision (DB unique index, code 23505) surfaces as
    /// `AuthError.nicknameTaken` so the UI can prompt for another.
    func updateProfile(displayName newName: String?, nickname newNickname: String?) async throws {
        guard let userId else { throw AuthError.notSignedIn }

        let trimmedName = newName?.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNick = newNickname?.trimmingCharacters(in: .whitespacesAndNewlines)

        let resolvedName = (trimmedName?.isEmpty == false) ? trimmedName : nil
        let resolvedNick = (trimmedNick?.isEmpty == false) ? trimmedNick : nil

        let row = ProfileRow(id: userId, fullName: resolvedName, email: email, nickname: resolvedNick)
        do {
            try await SupabaseAPI.client
                .from("user_profiles")
                .upsert(row, onConflict: "id")
                .execute()
        } catch {
            if Self.isUniqueViolation(error) { throw AuthError.nicknameTaken }
            throw error
        }

        if let resolvedName { displayName = resolvedName }
        if let resolvedNick { nickname = resolvedNick }
        persistIdentity()
        notifyAuthStateChanged()
    }

    /// True when the error is a Postgres unique-constraint violation (23505),
    /// which for `user_profiles` can only be the nickname index.
    private static func isUniqueViolation(_ error: Error) -> Bool {
        let text = "\(error)".lowercased()
        return text.contains("23505") || text.contains("duplicate key")
    }

    // MARK: - Private: Profile

    /// Pulls the stored `full_name` / `nickname` from the cloud and fills in
    /// anything we don't already have locally. A fresh Apple name (only handed
    /// to us on the very first authorization) always wins.
    private func loadCloudProfile(appleName: String? = nil) async {
        let cloud = await fetchCloudProfile()

        if let appleName, !appleName.isEmpty {
            displayName = appleName
        } else if let cloudName = cloud?.fullName, !cloudName.isEmpty {
            displayName = cloudName
        }

        if let cloudNickname = cloud?.nickname, !cloudNickname.isEmpty {
            nickname = cloudNickname
        }

        persistIdentity()
        notifyAuthStateChanged()
    }

    private func fetchCloudProfile() async -> ProfileResponse? {
        guard let userId else { return nil }
        do {
            let rows: [ProfileResponse] = try await SupabaseAPI.client
                .from("user_profiles")
                .select("full_name, nickname")
                .eq("id", value: userId)
                .limit(1)
                .execute()
                .value
            return rows.first
        } catch {
            print("[AuthManager] Fetch cloud profile failed: \(error)")
            return nil
        }
    }

    /// Seeds / refreshes the cloud profile during sign-in. `nil` fields are
    /// omitted from the payload (see `ProfileRow`) so we never blank out a name
    /// the cloud already holds when Apple gives us nothing on a reinstall.
    private func upsertProfile() async {
        guard let userId else { return }
        let row = ProfileRow(id: userId, fullName: displayName, email: email, nickname: nil)
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
            await pushSettings(
                notification: local.notification,
                darkMode: local.darkMode,
                hideTBD: local.hideTBD,
                autoRounds: local.autoRounds,
                language: local.language
            )
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

    private func pushSettings(notification: String, darkMode: Bool, hideTBD: Bool, autoRounds: [String], language: String) async {
        guard let userId else { return }
        let row = SettingsUpsertRow(
            userId: userId,
            notificationSetting: notification,
            darkMode: darkMode,
            hideTbd: hideTBD,
            laAutoRounds: autoRounds,
            language: language
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

        // Language last: applying it posts .appLanguageChanged, which rebuilds
        // the UI. Restoring the other preferences first means that rebuild
        // already reflects them.
        DispatchQueue.main.async {
            LanguageManager.shared.applyRemoteSelection(settings.language)
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

    private func currentLocalSettings() -> (notification: String, darkMode: Bool, hideTBD: Bool, autoRounds: [String], language: String) {
        let notification = UserDefaults.standard.string(forKey: DefaultsKey.notificationSetting)
            ?? NotificationSetting.allResults.rawValue
        let darkMode = UserDefaults.standard.bool(forKey: DefaultsKey.darkMode)
        let hideTBD = UserDefaults.standard.bool(forKey: DefaultsKey.hideTBD)
        let autoRounds = LiveActivityAutoRounds.selectedRawValues
        let language = LanguageManager.shared.selection.storedValue
        return (notification, darkMode, hideTBD, autoRounds, language)
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
    case nicknameTaken

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return L10n.Auth.notSignedIn
        case .nicknameTaken:
            return L10n.Auth.nicknameTaken
        }
    }
}

// MARK: - Row Models

private struct AppleCodeExchangeRequest: Encodable {
    let code: String
}

/// Encodes only the non-nil fields (`encodeIfPresent`) so a partial update —
/// e.g. setting just the nickname — leaves the other columns untouched on the
/// upsert's conflict path instead of nulling them out.
private struct ProfileRow: Encodable {
    let id: String
    let fullName: String?
    let email: String?
    let nickname: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case nickname
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(fullName, forKey: .fullName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(nickname, forKey: .nickname)
    }
}

/// Decoded with the shared client's `convertFromSnakeCase` strategy, so
/// `full_name` maps onto `fullName` automatically.
private struct ProfileResponse: Decodable {
    let fullName: String?
    let nickname: String?
}

private struct SettingsUpsertRow: Encodable {
    let userId: String
    let notificationSetting: String
    let darkMode: Bool
    let hideTbd: Bool
    let laAutoRounds: [String]
    let language: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case notificationSetting = "notification_setting"
        case darkMode = "dark_mode"
        case hideTbd = "hide_tbd"
        case laAutoRounds = "la_auto_rounds"
        case language
    }
}

/// Decoded with the shared client's `convertFromSnakeCase` strategy, so the
/// snake_case columns map onto these camelCase properties automatically.
private struct SettingsResponse: Decodable {
    let notificationSetting: String
    let darkMode: Bool?
    let hideTbd: Bool?
    let laAutoRounds: [String]?
    /// A language code, or "system" to follow the device. Optional so rows
    /// written before the column existed still decode.
    let language: String?
}

// MARK: - Notification Names

extension Notification.Name {
    static let authStateChanged = Notification.Name("authStateChanged")
}
