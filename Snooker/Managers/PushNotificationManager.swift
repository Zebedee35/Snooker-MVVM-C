//
//  PushNotificationManager.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 15.01.2026.
//

import UIKit
import UserNotifications
import Supabase

// MARK: - Push Notification Manager

final class PushNotificationManager: NSObject {
    
    static let shared = PushNotificationManager()
    
    private override init() {
        super.init()
    }
    
    // MARK: - Device Token
    
    private(set) var deviceToken: String? {
        didSet {
            if let token = deviceToken {
                UserDefaults.standard.set(token, forKey: "device_token")
                print("[PushNotificationManager] Device token saved: \(token)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// Request notification permission and register for remote notifications
    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("[PushNotificationManager] Notification permission granted")
                } else {
                    print("[PushNotificationManager] Notification permission denied: \(error?.localizedDescription ?? "Unknown")")
                }
                completion(granted)
            }
        }
    }
    
    /// Check current notification authorization status
    func checkAuthorizationStatus(completion: @escaping @Sendable (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let status = settings.authorizationStatus
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    /// Handle device token received from APNs
    func handleDeviceToken(_ deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        self.deviceToken = token
        
        // Register token to Supabase
        Task {
            await registerTokenToSupabase(token: token)
        }
    }
    
    /// Handle device token registration failure
    func handleRegistrationError(_ error: Error) {
        print("[PushNotificationManager] Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    /// Get current notification setting from UserDefaults
    func getCurrentNotificationSetting() -> NotificationSetting {
        if let savedSetting = UserDefaults.standard.string(forKey: "notification_setting"),
           let setting = NotificationSetting(rawValue: savedSetting) {
            return setting
        }
        return .allResults
    }
    
    /// Update notification setting on server
    func updateNotificationSetting(_ setting: NotificationSetting) {
        UserDefaults.standard.set(setting.rawValue, forKey: "notification_setting")
        
        guard let token = deviceToken ?? UserDefaults.standard.string(forKey: "device_token") else {
            print("[PushNotificationManager] No device token available")
            return
        }
        
        Task {
            await updateSettingOnSupabase(token: token, setting: setting)
        }
    }
    
    /// Stamp the current device token row with the signed-in user (or clear it
    /// on sign-out) so the notification preference can follow the account.
    func linkDeviceToUser(userId: String?) {
        guard let token = deviceToken ?? UserDefaults.standard.string(forKey: "device_token") else {
            print("[PushNotificationManager] No device token available to link")
            return
        }

        Task {
            do {
                try await SupabaseAPI.client
                    .from("device_tokens")
                    .update(["user_id": userId])
                    .eq("token", value: token)
                    .execute()

                print("[PushNotificationManager] Device token linked to user: \(userId ?? "nil")")
            } catch {
                print("[PushNotificationManager] Failed to link device token to user: \(error)")
            }
        }
    }

    // MARK: - Test Notification

    /// Sends a single test push to THIS device only, via the
    /// `send-test-notification` Edge Function. The function verifies the token
    /// belongs to the signed-in caller, so it can never reach another user's
    /// device. Throws if there is no token or the function reports a failure.
    func sendTestNotification() async throws {
        guard let token = deviceToken ?? UserDefaults.standard.string(forKey: "device_token") else {
            throw TestNotificationError.noDeviceToken
        }
        try await SupabaseAPI.client.functions.invoke(
            "send-test-notification",
            options: .init(body: ["token": token])
        )
    }

    // MARK: - Private Methods

    private func registerTokenToSupabase(token: String) async {
        let setting = getCurrentNotificationSetting()

        do {
            try await SupabaseAPI.client
                .from("device_tokens")
                .upsert([
                    "token": token,
                    "platform": "ios",
                    "notification_setting": setting.rawValue,
                    "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ], onConflict: "token")
                .execute()

            print("[PushNotificationManager] Token registered to Supabase successfully")

            // Keep the backend's auto-round selection in sync so it can
            // push-to-start Live Activities while the app is closed.
            await updateLiveActivityAutoRoundsOnSupabase(
                token: token,
                rounds: LiveActivityAutoRounds.selectedRawValues
            )
        } catch {
            print("[PushNotificationManager] Failed to register token to Supabase: \(error)")
        }
    }

    /// Push the user's auto-follow round selection to `device_tokens.la_auto_rounds`.
    /// Used both on token registration and whenever the Settings toggles change.
    func updateLiveActivityAutoRounds(_ rounds: [String]) {
        guard let token = deviceToken ?? UserDefaults.standard.string(forKey: "device_token") else {
            print("[PushNotificationManager] No device token to update auto-rounds")
            return
        }
        Task {
            await updateLiveActivityAutoRoundsOnSupabase(token: token, rounds: rounds)
        }
    }

    private struct AutoRoundsUpdate: Encodable {
        let laAutoRounds: [String]
        let updatedAt: String

        enum CodingKeys: String, CodingKey {
            case laAutoRounds = "la_auto_rounds"
            case updatedAt = "updated_at"
        }
    }

    private func updateLiveActivityAutoRoundsOnSupabase(token: String, rounds: [String]) async {
        do {
            let payload = AutoRoundsUpdate(
                laAutoRounds: rounds,
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            try await SupabaseAPI.client
                .from("device_tokens")
                .update(payload)
                .eq("token", value: token)
                .execute()
            print("[PushNotificationManager] Live Activity auto-rounds updated: \(rounds)")
        } catch {
            print("[PushNotificationManager] Failed to update auto-rounds: \(error)")
        }
    }
    
    private func updateSettingOnSupabase(token: String, setting: NotificationSetting) async {
        do {
            try await SupabaseAPI.client
                .from("device_tokens")
                .update([
                    "notification_setting": setting.rawValue,
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .eq("token", value: token)
                .execute()
            
            print("[PushNotificationManager] Notification setting updated on Supabase")
        } catch {
            print("[PushNotificationManager] Failed to update setting on Supabase: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationManager: UNUserNotificationCenterDelegate {
    
    /// Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("[PushNotificationManager] Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        print("[PushNotificationManager] Notification tapped: \(userInfo)")
        
        // Handle deep linking based on notification payload
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        // Extract match or tournament info from payload
        if let matchId = userInfo["match_id"] as? String {
            // Post notification for navigation
            NotificationCenter.default.post(
                name: .pushNotificationTapped,
                object: nil,
                userInfo: ["match_id": matchId]
            )
        } else if let tournamentId = userInfo["tournament_id"] as? String {
            NotificationCenter.default.post(
                name: .pushNotificationTapped,
                object: nil,
                userInfo: ["tournament_id": tournamentId]
            )
        }
    }
}

// MARK: - Errors

enum TestNotificationError: LocalizedError {
    case noDeviceToken

    var errorDescription: String? {
        switch self {
        case .noDeviceToken:
            return "No device token yet. Make sure notifications are allowed and try again."
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let pushNotificationTapped = Notification.Name("pushNotificationTapped")
}
