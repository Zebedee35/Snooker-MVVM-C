//
//  LanguageManager.swift
//  Snooker
//
//  Owns which language the app renders in, and hands out the resource bundle
//  every localized lookup goes through.
//
//  The list of languages is *derived from the bundle*, never hardcoded: adding
//  a language to Localizable.xcstrings makes it appear in the picker on the
//  next build, with no code change here.
//

import Foundation

// MARK: - Language

/// A language the app ships translations for.
nonisolated struct AppLanguage: Hashable {

    /// BCP-47 code as it appears in the bundle, e.g. "en", "tr", "zh-Hans".
    let code: String

    /// The language's name *in that language* — "Türkçe", "Deutsch", "简体中文".
    /// This is what a speaker of the language looks for in a picker, so it is
    /// the primary label.
    var endonym: String {
        let locale = Locale(identifier: code)
        let name = locale.localizedString(forIdentifier: code) ?? code
        return name.capitalizedFirstLetter(in: locale)
    }

    /// The language's name in whatever language the app is currently showing —
    /// "Turkish" while the app is in English. Used as a secondary label so a
    /// user who picked the wrong language can still find their way back.
    var exonym: String {
        let display = LanguageManager.shared.locale
        let name = display.localizedString(forIdentifier: code) ?? code
        return name.capitalizedFirstLetter(in: display)
    }
}

// MARK: - Selection

/// What the user picked, as opposed to what that currently resolves to.
/// `.system` keeps following iOS if the device language later changes.
nonisolated enum LanguageSelection: Equatable, Sendable {
    case system
    case explicit(String)

    var storedValue: String {
        switch self {
        case .system:             return Self.systemToken
        case .explicit(let code): return code
        }
    }

    init(storedValue: String?) {
        guard let storedValue, storedValue != Self.systemToken else {
            self = .system
            return
        }
        self = .explicit(storedValue)
    }

    fileprivate static let systemToken = "system"
}

// MARK: - Manager

/// Strings are read from wherever they are needed — including nonisolated
/// contexts like `LocalizedError.errorDescription` — so this type stays off
/// the main actor and guards its own state with a lock instead.
nonisolated final class LanguageManager: @unchecked Sendable {

    static let shared = LanguageManager()

    private enum Keys {
        static let selection = "app_language"
        /// Read by iOS itself. We mirror our choice here so system-drawn UI
        /// (share sheet, keyboard, search bar's Cancel) matches after a relaunch.
        static let appleLanguages = "AppleLanguages"
    }

    private let defaults: UserDefaults

    /// Guards `storedSelection` and `resolvedBundle`, which are written from
    /// the main thread but read from any.
    private let lock = NSLock()
    private var storedSelection: LanguageSelection
    private var resolvedBundle: Bundle

    private init(defaults: UserDefaults = .standard) {
        let initial = LanguageSelection(storedValue: defaults.string(forKey: Keys.selection))
        self.defaults = defaults
        self.storedSelection = initial
        self.resolvedBundle = Self.resolveBundle(for: Self.resolveCode(for: initial))
    }

    // MARK: State

    /// The user's choice, as opposed to what it resolves to.
    var selection: LanguageSelection {
        lock.lock()
        defer { lock.unlock() }
        return storedSelection
    }

    /// The `.lproj` bundle localized lookups read from. Falls back to
    /// `Bundle.main` when the resolved language has no catalog of its own.
    var bundle: Bundle {
        lock.lock()
        defer { lock.unlock() }
        return resolvedBundle
    }

    /// The language actually being rendered, after resolving `.system`.
    var resolvedCode: String { Self.resolveCode(for: selection) }

    /// Locale for every user-facing formatter (dates, numbers, currency) so
    /// they follow the in-app language rather than the device's.
    var locale: Locale { Locale(identifier: resolvedCode) }

    /// Languages the bundle actually carries a translation for, with the
    /// development language first and the rest sorted by their native name.
    var availableLanguages: [AppLanguage] {
        let codes = Bundle.main.localizations.filter { $0 != "Base" }
        let development = Bundle.main.developmentLocalization
        return codes
            .map(AppLanguage.init(code:))
            .sorted { lhs, rhs in
                if lhs.code == development { return true }
                if rhs.code == development { return false }
                return lhs.endonym.localizedCaseInsensitiveCompare(rhs.endonym) == .orderedAscending
            }
    }

    /// True once there is something to choose between — used to hide the
    /// Settings row while the app is still English-only.
    var hasMultipleLanguages: Bool { availableLanguages.count > 1 }

    // MARK: Mutation

    func setSelection(_ newSelection: LanguageSelection) {
        lock.lock()
        guard newSelection != storedSelection else {
            lock.unlock()
            return
        }
        storedSelection = newSelection
        resolvedBundle = Self.resolveBundle(for: Self.resolveCode(for: newSelection))
        lock.unlock()

        defaults.set(newSelection.storedValue, forKey: Keys.selection)
        applyToAppleLanguages(newSelection)

        // Observers rebuild UIKit view hierarchies, so deliver on the main
        // queue regardless of where the change was made from (cloud sync
        // arrives on a background task).
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .appLanguageChanged, object: nil)
        }
    }

    /// Applies a selection restored from the user's cloud record.
    func applyRemoteSelection(_ storedValue: String?) {
        guard let storedValue else { return }
        setSelection(LanguageSelection(storedValue: storedValue))
    }

    // MARK: Lookup

    /// Every localized string in the app funnels through here.
    func string(_ key: String, table: String? = nil) -> String {
        bundle.localizedString(forKey: key, value: nil, table: table)
    }

    // MARK: Resolution

    /// Picks the best available translation for a selection.
    ///
    /// For `.system` this defers to Foundation's own negotiation
    /// (`preferredLocalizations`), which already handles the awkward cases —
    /// a device set to `de-AT` matching our `de`, or `zh-Hant-HK` matching
    /// `zh-Hant` — rather than us re-implementing BCP-47 matching badly.
    private static func resolveCode(for selection: LanguageSelection) -> String {
        let available = Bundle.main.localizations.filter { $0 != "Base" }
        let fallback = Bundle.main.developmentLocalization ?? "en"

        switch selection {
        case .system:
            return Bundle.preferredLocalizations(
                from: available,
                forPreferences: Locale.preferredLanguages
            ).first ?? fallback

        case .explicit(let code):
            // A stored code can go stale — a language may be pulled from a
            // later build. Re-negotiate rather than trusting it blindly.
            guard available.contains(code) else {
                return Bundle.preferredLocalizations(
                    from: available,
                    forPreferences: [code]
                ).first ?? fallback
            }
            return code
        }
    }

    private static func resolveBundle(for code: String) -> Bundle {
        guard let path = Bundle.main.path(forResource: code, ofType: "lproj"),
              let localized = Bundle(path: path) else {
            return .main
        }
        return localized
    }

    /// Mirrors the choice into `AppleLanguages`. This only takes effect for
    /// system-drawn UI on the *next* launch — our own strings switch
    /// immediately via `bundle`, so the two are briefly out of step for
    /// things like the keyboard. That is the accepted trade-off for not
    /// forcing a restart.
    private func applyToAppleLanguages(_ selection: LanguageSelection) {
        switch selection {
        case .system:
            defaults.removeObject(forKey: Keys.appleLanguages)
        case .explicit(let code):
            defaults.set([code], forKey: Keys.appleLanguages)
        }
    }
}

// MARK: - Notification

extension Notification.Name {
    /// Posted after the app language changes. The root coordinator rebuilds
    /// the UI in response; individual screens do not need to observe it.
    static let appLanguageChanged = Notification.Name("appLanguageChanged")
}

// MARK: - Helpers

private nonisolated extension String {
    /// Locale-correct first-letter capitalisation for display names.
    /// Foundation hands back "türkçe" / "deutsch" lowercased for some
    /// identifiers, and plain `capitalized` would break the Turkish i.
    func capitalizedFirstLetter(in locale: Locale) -> String {
        guard let first else { return self }
        return String(first).uppercased(with: locale) + dropFirst()
    }
}
