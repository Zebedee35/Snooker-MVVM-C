//
//  MatchStatusName.swift
//  Snooker
//
//  Match status arrives from the backend as an English keyword ("live",
//  "break", "finished"). Like RoundName, this maps that data onto catalog
//  keys at the point of display, leaving the raw value intact for logic.
//
//  Shared by the app and the Live Activity widget so a status pill reads the
//  same in both places.
//

import Foundation

nonisolated enum MatchStatusName {

    /// Badge form, shown in capitals in a small pill: "LIVE", "ON BREAK".
    /// Returns nil for a status we don't recognise, so the caller can fall
    /// back to showing the raw keyword rather than an empty pill.
    static func badge(_ raw: String) -> String? {
        switch raw.lowercased() {
        case "live":                  return L10n.MatchStatus.live
        case "break":                 return L10n.MatchStatus.onBreak
        case "completed", "finished": return L10n.MatchStatus.complete
        case "scheduled":             return L10n.MatchStatus.scheduled
        case "suspended":             return L10n.MatchStatus.suspended
        default:                      return nil
        }
    }

    /// Badge form with a sensible fallback: an unrecognised status is shown
    /// as-is, uppercased, which is what the screens did before translation.
    static func badgeOrRaw(_ raw: String) -> String {
        badge(raw) ?? raw.uppercased(with: LanguageManager.shared.locale)
    }
}
