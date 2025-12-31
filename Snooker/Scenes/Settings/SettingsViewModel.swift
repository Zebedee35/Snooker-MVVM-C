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
}

// MARK: - Settings Item

struct SettingsItem {
    let id: String
    let icon: String?        // SF Symbol veya emoji
    let iconColor: UIColor?
    let title: String
    let subtitle: String?
    let type: SettingsItemType
    var isSelected: Bool     // Radio için
    var isOn: Bool           // Toggle için
    let appIconName: String? // App cell için
    
    init(
        id: String,
        icon: String? = nil,
        iconColor: UIColor? = nil,
        title: String,
        subtitle: String? = nil,
        type: SettingsItemType,
        isSelected: Bool = false,
        isOn: Bool = false,
        appIconName: String? = nil
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
    }
    
    private func loadSettings() {
        // TODO: Load from UserDefaults
        if let savedNotification = UserDefaults.standard.string(forKey: "notification_setting"),
           let setting = NotificationSetting(rawValue: savedNotification) {
            notificationSetting = setting
        }
        isDarkMode = UserDefaults.standard.bool(forKey: "dark_mode")
        hideTBDMatches = UserDefaults.standard.bool(forKey: "hide_tbd_matches")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(notificationSetting.rawValue, forKey: "notification_setting")
        UserDefaults.standard.set(isDarkMode, forKey: "dark_mode")
        UserDefaults.standard.set(hideTBDMatches, forKey: "hide_tbd_matches")
    }
    
    private func buildSections() {
        sections = [
            buildNotificationSection(),
            buildOtherSection(),
            buildOurAppsSection(),
            buildAboutSection()
        ]
    }
    
    private func buildNotificationSection() -> SettingsSection {
        let items = NotificationSetting.allCases.map { setting in
            SettingsItem(
                id: "notification_\(setting.rawValue)",
                title: setting.title,
                type: .radio,
                isSelected: notificationSetting == setting
            )
        }
        return SettingsSection(title: "NOTIFICATION", items: items)
    }
    
    private func buildOtherSection() -> SettingsSection {
        let items = [
            SettingsItem(
                id: "change_app_icon",
                icon: "🌠",
                title: "Change App Icon",
                type: .navigation
            ),
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
                icon: "🎬",
                title: "FilmBox",
                subtitle: "Smart Movie Manager",
                type: .app,
                appIconName: "filmbox_icon"
            ),
            SettingsItem(
                id: "contactname_app",
                icon: "👤",
                title: "ContactName",
                subtitle: "Update Your Contacts",
                type: .app,
                appIconName: "contactname_icon"
            )
        ]
        return SettingsSection(title: "OUR APPS", items: items)
    }
    
    private func buildAboutSection() -> SettingsSection {
        let items = [
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
            }
            
        // Other section
        case "change_app_icon":
            delegate?.navigateTo(route: .changeAppIcon)
            
        // Our Apps section
        case "filmbox_app":
            delegate?.navigateTo(route: .filmBoxApp)
        case "contactname_app":
            delegate?.navigateTo(route: .contactNameApp)
            
        // About section
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
            
        case "hide_tbd":
            hideTBDMatches = isOn
            saveSettings()
            // TODO: Notify other screens about TBD filter change
            NotificationCenter.default.post(name: .hideTBDMatchesChanged, object: nil, userInfo: ["isHidden": isOn])
            
        default:
            break
        }
    }
    
    private func applyDarkMode(_ isDark: Bool) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.overrideUserInterfaceStyle = isDark ? .dark : .unspecified
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let hideTBDMatchesChanged = Notification.Name("hideTBDMatchesChanged")
}
