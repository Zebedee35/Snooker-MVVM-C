//
//  MatchRoundCategory.swift
//  Snooker
//
//  Classifies a match's `round` string into the coarse buckets the user can
//  opt into for automatic Live Activities, and stores that opt-in preference.
//

import Foundation

// MARK: - Round Category

/// The rounds a user can choose to always auto-follow on the Lock Screen.
/// Matching is intentionally fuzzy because the upstream `round` strings vary
/// ("Final", "Group Final", "Semi-Finals", "Quarter Final", …).
enum MatchRoundCategory: String, CaseIterable {
    case final
    case semiFinal
    case quarterFinal

    var title: String {
        switch self {
        case .final:        return L10n.Round.final
        case .semiFinal:    return L10n.Round.semiFinal
        case .quarterFinal: return L10n.Round.quarterFinal
        }
    }

    /// Best-effort mapping from a raw round string to a category.
    /// Order matters: "Semi Final" / "Quarter Final" both contain "final", so
    /// those are matched first.
    static func category(for round: String) -> MatchRoundCategory? {
        let r = round.lowercased()
        if r.contains("semi") { return .semiFinal }
        if r.contains("quarter") { return .quarterFinal }
        if r.contains("final") { return .final }
        return nil
    }
}

// MARK: - Auto-Rounds Preference Store

/// The user's "always show on Lock Screen" round selection, persisted locally.
/// Mirrored to `device_tokens.la_auto_rounds` so the backend can push-to-start
/// activities while the app is closed (iOS 17.2+).
enum LiveActivityAutoRounds {

    static let defaultsKey = "live_activity_auto_rounds"

    static var selected: Set<MatchRoundCategory> {
        get {
            let raw = UserDefaults.standard.stringArray(forKey: defaultsKey) ?? []
            return Set(raw.compactMap { MatchRoundCategory(rawValue: $0) })
        }
        set {
            let raw = newValue.map { $0.rawValue }
            UserDefaults.standard.set(raw, forKey: defaultsKey)
        }
    }

    static func isOn(_ category: MatchRoundCategory) -> Bool {
        selected.contains(category)
    }

    static func set(_ category: MatchRoundCategory, on: Bool) {
        var current = selected
        if on { current.insert(category) } else { current.remove(category) }
        selected = current
    }

    /// True if a match in this round should auto-start a Live Activity.
    static func shouldAutoFollow(round: String) -> Bool {
        guard let category = MatchRoundCategory.category(for: round) else { return false }
        return selected.contains(category)
    }

    /// Raw values for syncing to the backend (e.g. `["final", "semiFinal"]`).
    static var selectedRawValues: [String] {
        selected.map { $0.rawValue }.sorted()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the user changes which rounds auto-follow on the Lock Screen.
    static let liveActivityAutoRoundsChanged = Notification.Name("liveActivityAutoRoundsChanged")
}
