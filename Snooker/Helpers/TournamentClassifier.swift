//
//  TournamentClassifier.swift
//  Snooker
//
//  Heuristics for deciding what kind of event a tournament is, from its name.
//  Used (for now) to gate the bracket button to knockout main events.
//

import Foundation

enum TournamentClassifier {

    /// Main ("Triple Crown" + ranking) events that have a proper knockout draw.
    /// Mirrors the `main_tournaments` ILIKE patterns in 01_push_notification_setup.sql
    /// — keep the two in sync. Matched case-insensitively as substrings, so
    /// "masters" already covers German / European / Shanghai Masters.
    private static let mainPatterns: [String] = [
        "world championship",
        "uk championship",
        "masters",
        "tour championship",
        "champion of champions",
        "world grand prix",
        "players championship",
        "british open",
        "welsh open",
        "northern ireland open",
        "scottish open",
        "english open",
        "international championship",
        "china open"
    ]

    /// A qualifying event (e.g. "World Championship 2027 Qualifiers"). These
    /// carry a main event's name but are not the main knockout draw, so they
    /// must never be treated as main.
    static func isQualifier(_ name: String) -> Bool {
        name.lowercased().contains("qualif")   // "Qualifier" / "Qualifiers" / "Qualifying"
    }

    /// True when the name matches a known main event AND isn't its qualifier.
    static func isMain(_ name: String) -> Bool {
        guard !isQualifier(name) else { return false }
        let lower = name.lowercased()
        return mainPatterns.contains { lower.contains($0) }
    }
}
