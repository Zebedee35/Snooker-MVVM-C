//
//  SettingsViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

// MARK: - Settings Item Type

enum SettingsItemType {
    case navigation   // Chevron ile navigation
    case toggle       // Switch toggle
    case radio        // Radio button (checkmark)
    case action       // Tek action (share, rate vs)
    case app          // App promotion
    case appleSignIn  // Sign in with Apple button
    case profile      // Signed-in user profile (name + email)
}

// MARK: - Settings Item

struct SettingsItem {
    let id: String
    let icon: String?        // SF Symbol veya emoji
    let iconColor: UIColor?
    let title: String
    let subtitle: String?
    let type: SettingsItemType
    var isSelected: Bool      // Radio için
    var isOn: Bool            // Toggle için
    let appIconName: String?  // App cell için
    let isDestructive: Bool   // Kırmızı action (Sign Out) için

    init(
        id: String,
        icon: String? = nil,
        iconColor: UIColor? = nil,
        title: String,
        subtitle: String? = nil,
        type: SettingsItemType,
        isSelected: Bool = false,
        isOn: Bool = false,
        appIconName: String? = nil,
        isDestructive: Bool = false
    ) {
        self.id = id
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.type = type
        self.isSelected = isSelected
        self.isOn = isOn
        self.appIconName = appIconName
        self.isDestructive = isDestructive
    }
}

// MARK: - Settings Section

struct SettingsSection {
    let title: String
    var items: [SettingsItem]
}

// MARK: - Notification Setting

enum NotificationSetting: String, CaseIterable {
    case allResults = "all_results"
    case mainEvents = "main_events"
    case finalsOnly = "finals_only"
    case none = "none"
    
    var title: String {
        switch self {
        case .allResults: return "All Results"
        case .mainEvents: return "All Results For Main Events"
        case .finalsOnly: return "Only Finals Results for Main Events"
        case .none: return "None (Never send Notifications)"
        }
    }

    var icon: String {
        switch self {
        case .allResults: return "bell.badge.fill"
        case .mainEvents: return "star.fill"
        case .finalsOnly: return "trophy.fill"
        case .none: return "bell.slash.fill"
        }
    }

    var iconColor: UIColor {
        switch self {
        case .allResults: return .systemRed
        case .mainEvents: return .systemOrange
        case .finalsOnly: return .systemYellow
        case .none: return .systemGray
        }
    }
}

// MARK: - Protocol

protocol SettingsViewModelProtocol {
    var sections: [SettingsSection] { get }
    var appVersion: String { get }
    var delegate: SettingsViewModelDelegate? { get set }
    
    func handleSelection(item: SettingsItem)
    func handleToggle(item: SettingsItem, isOn: Bool)
}

// MARK: - Delegate

protocol SettingsViewModelDelegate: AnyObject {
    func settingsDidUpdate()
    func navigateTo(route: SettingsRoute)
}

// MARK: - Route

enum SettingsRoute {
    case changeAppIcon
    case filmBoxApp
    case contactNameApp
    case rateUs
    case shareApp
    case giveFeedback
    case website
    case announcementsHistory
    case signInWithApple
    case signOut
    case deleteAccount
}

// MARK: - ViewModel

final class SettingsViewModel: SettingsViewModelProtocol {
    
    weak var delegate: SettingsViewModelDelegate?
    
    private(set) var sections: [SettingsSection] = []
    
    // Settings state
    private var notificationSetting: NotificationSetting = .allResults
    private var isDarkMode: Bool = false
    private var hideTBDMatches: Bool = false
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    init() {
        loadSettings()
        buildSections()

        // Rebuild when auth state or cloud-synced settings change.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAuthStateChanged),
            name: .authStateChanged,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleAuthStateChanged() {
        loadSettings()
        buildSections()
        delegate?.settingsDidUpdate()
    }

    private func loadSettings() {
        // TODO: Load from UserDefaults
        if let savedNotification = UserDefaults.standard.string(forKey: "notification_setting"),
           let setting = NotificationSetting(rawValue: savedNotification) {
            notificationSetting = setting
        }
        
        // Dark Mode: İlk kez açılıyorsa sistemin modunu kullan ve kaydet
        if UserDefaults.standard.object(forKey: "dark_mode") == nil {
            // İlk açılış - sistemin modunu kontrol et
            let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
            isDarkMode = systemIsDark
            UserDefaults.standard.set(isDarkMode, forKey: "dark_mode")
        } else {
            isDarkMode = UserDefaults.standard.bool(forKey: "dark_mode")
        }
        
        // Dark Mode'u uygula
        applyDarkMode(isDarkMode)
        
        hideTBDMatches = UserDefaults.standard.bool(forKey: "hide_tbd_matches")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(notificationSetting.rawValue, forKey: "notification_setting")
        UserDefaults.standard.set(isDarkMode, forKey: "dark_mode")
        UserDefaults.standard.set(hideTBDMatches, forKey: "hide_tbd_matches")
    }
    
    private func buildSections() {
        sections = [
            buildAccountSection(),
            buildNotificationSection(),
            buildLiveActivitySection(),
            buildOtherSection(),
            buildOurAppsSection(),
            buildAboutSection()
        ]
    }

    /// Rounds the user wants to *always* see on the Lock Screen (auto Live
    /// Activity). Any other match can still be followed manually via the bell.
    private func buildLiveActivitySection() -> SettingsSection {
        let rows: [(MatchRoundCategory, String, UIColor)] = [
            (.final, "trophy.fill", .systemYellow),
            (.semiFinal, "rosette", .systemOrange),
            (.quarterFinal, "flag.checkered", .systemTeal)
        ]
        let items = rows.map { category, icon, color in
            SettingsItem(
                id: "la_round_\(category.rawValue)",
                icon: icon,
                iconColor: color,
                title: category.title,
                type: .toggle,
                isOn: LiveActivityAutoRounds.isOn(category)
            )
        }
        return SettingsSection(title: "AUTO LOCK SCREEN (LIVE ACTIVITY)", items: items)
    }

    private func buildAccountSection() -> SettingsSection {
        if AuthManager.shared.isSignedIn {
            let name = AuthManager.shared.displayName
            let email = AuthManager.shared.email
            let items = [
                SettingsItem(
                    id: "profile",
                    title: (name?.isEmpty == false ? name : nil) ?? "Signed in",
                    subtitle: email,
                    type: .profile
                ),
                SettingsItem(
                    id: "sign_out",
                    icon: "rectangle.portrait.and.arrow.right",
                    iconColor: .systemRed,
                    title: "Sign Out",
                    type: .action,
                    isDestructive: true
                ),
                SettingsItem(
                    id: "delete_account",
                    icon: "trash",
                    iconColor: .systemRed,
                    title: "Delete Account",
                    type: .action,
                    isDestructive: true
                )
            ]
            return SettingsSection(title: "ACCOUNT", items: items)
        } else {
            let items = [
                SettingsItem(
                    id: "apple_signin",
                    title: "Sign in with Apple",
                    type: .appleSignIn
                )
            ]
            return SettingsSection(title: "ACCOUNT", items: items)
        }
    }
    
    private func buildNotificationSection() -> SettingsSection {
        let items = NotificationSetting.allCases.map { setting in
            SettingsItem(
                id: "notification_\(setting.rawValue)",
                icon: setting.icon,
                iconColor: setting.iconColor,
                title: setting.title,
                type: .radio,
                isSelected: notificationSetting == setting
            )
        }
        return SettingsSection(title: "NOTIFICATION", items: items)
    }
    
    private func buildOtherSection() -> SettingsSection {
        let items = [
            /* SettingsItem(
                id: "change_app_icon",
                icon: "🌠",
                title: "Change App Icon",
                type: .navigation
            ),
             */
            SettingsItem(
                id: "dark_mode",
                icon: "moon.fill",
                iconColor: .systemIndigo,
                title: "Dark Mode",
                type: .toggle,
                isOn: isDarkMode
            ),
            SettingsItem(
                id: "hide_tbd",
                icon: "eye.slash.fill",
                iconColor: .systemOrange,
                title: "Hide TBD Matches",
                type: .toggle,
                isOn: hideTBDMatches
            )
        ]
        return SettingsSection(title: "OTHER", items: items)
    }
    
    private func buildOurAppsSection() -> SettingsSection {
        let items = [
            SettingsItem(
                id: "filmbox_app",
                title: "FilmBox",
                subtitle: "Smart Movie Manager",
                type: .app,
                appIconName: "Filmbox"
            ),
            SettingsItem(
                id: "contactname_app",
                title: "ContactName",
                subtitle: "Update Your Contacts",
                type: .app,
                appIconName: "ContactName"
            )
        ]
        return SettingsSection(title: "OUR APPS", items: items)
    }
    
    private func buildAboutSection() -> SettingsSection {
        let items = [
            SettingsItem(
                id: "announcements_history",
                icon: "bell.badge",
                iconColor: .systemPurple,
                title: "Announcements",
                type: .navigation
            ),
            SettingsItem(
                id: "rate_us",
                icon: "star.fill",
                iconColor: .systemYellow,
                title: "Rate Us",
                type: .action
            ),
            SettingsItem(
                id: "share_app",
                icon: "square.and.arrow.up",
                iconColor: .systemBlue,
                title: "Share App",
                type: .action
            ),
            SettingsItem(
                id: "give_feedback",
                icon: "bubble.left.and.bubble.right.fill",
                iconColor: .systemGreen,
                title: "Give Feedback",
                type: .action
            ),
            SettingsItem(
                id: "website",
                icon: "globe",
                iconColor: .systemTeal,
                title: "35Coders.com",
                type: .action
            )
        ]
        return SettingsSection(title: "ABOUT US", items: items)
    }
    
    func handleSelection(item: SettingsItem) {
        switch item.id {
        // Notification radio buttons
        case let id where id.hasPrefix("notification_"):
            let settingId = String(id.dropFirst("notification_".count))
            if let setting = NotificationSetting(rawValue: settingId) {
                notificationSetting = setting
                saveSettings()
                buildSections()
                delegate?.settingsDidUpdate()
                
                // Update notification setting on Supabase
                PushNotificationManager.shared.updateNotificationSetting(setting)
                syncSettingsToCloud()
            }

        // Account section
        case "apple_signin":
            delegate?.navigateTo(route: .signInWithApple)
        case "sign_out":
            delegate?.navigateTo(route: .signOut)
        case "delete_account":
            delegate?.navigateTo(route: .deleteAccount)

        // Other section
        case "change_app_icon":
            delegate?.navigateTo(route: .changeAppIcon)
            
        // Our Apps section
        case "filmbox_app":
            delegate?.navigateTo(route: .filmBoxApp)
        case "contactname_app":
            delegate?.navigateTo(route: .contactNameApp)
            
        // About section
        case "announcements_history":
            delegate?.navigateTo(route: .announcementsHistory)

        case "rate_us":
            delegate?.navigateTo(route: .rateUs)
        case "share_app":
            delegate?.navigateTo(route: .shareApp)
        case "give_feedback":
            delegate?.navigateTo(route: .giveFeedback)
        case "website":
            delegate?.navigateTo(route: .website)
            
        default:
            break
        }
    }
    
    func handleToggle(item: SettingsItem, isOn: Bool) {
        switch item.id {
        case "dark_mode":
            isDarkMode = isOn
            saveSettings()
            applyDarkMode(isOn)
            syncSettingsToCloud()

        case "hide_tbd":
            hideTBDMatches = isOn
            saveSettings()
            // TODO: Notify other screens about TBD filter change
            NotificationCenter.default.post(name: .hideTBDMatchesChanged, object: nil, userInfo: ["isHidden": isOn])
            syncSettingsToCloud()

        case let id where id.hasPrefix("la_round_"):
            let raw = String(id.dropFirst("la_round_".count))
            if let category = MatchRoundCategory(rawValue: raw) {
                LiveActivityAutoRounds.set(category, on: isOn)
                // Mirror to the backend so it can push-to-start while closed.
                PushNotificationManager.shared.updateLiveActivityAutoRounds(
                    LiveActivityAutoRounds.selectedRawValues
                )
                // Follow the account across devices via user_settings.
                syncSettingsToCloud()
                // Tell the Live screen to start any now-qualifying activities.
                NotificationCenter.default.post(name: .liveActivityAutoRoundsChanged, object: nil)
            }

        default:
            break
        }

        // Rebuild the model so reused cells reflect the new toggle state.
        // (No reload here — the visible switch already shows the new value;
        //  this just keeps `sections` from handing a stale isOn to cell reuse.)
        buildSections()
    }

    /// Push the current local preferences to the signed-in user's cloud record.
    private func syncSettingsToCloud() {
        AuthManager.shared.syncSettingsToCloud(
            notification: notificationSetting.rawValue,
            darkMode: isDarkMode,
            hideTBD: hideTBDMatches,
            autoRounds: LiveActivityAutoRounds.selectedRawValues
        )
    }
    
    private func applyDarkMode(_ isDark: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = isDark ? .dark : .light
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hideTBDMatchesChanged = Notification.Name("hideTBDMatchesChanged")
}
