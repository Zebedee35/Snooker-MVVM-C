//
//  RoundName.swift
//  Snooker
//
//  Round names reach us as free-form English from the upstream feed
//  ("Semi-Finals", "Round 1 (Held Over)", "League Phase (STAGE ONE / WEEK 2)").
//  They are data, not UI copy, so they can't live in the String Catalog
//  directly — this maps them onto keys that can.
//
//  Anything unrecognised is passed through unchanged. A new round name from
//  the feed therefore shows in English rather than breaking the screen, which
//  is the right failure mode: readable, and obvious in a bug report.
//

import Foundation

nonisolated enum RoundName {

    /// Localizes a round string from the backend.
    static func localized(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }

        // "Round 1 (Held Over)" / "Qualifier 2 (heldover)" — peel the suffix
        // off, translate the round underneath, then re-wrap it.
        if let base = heldOverBase(of: trimmed) {
            return L10n.Round.heldOver(localized(base))
        }

        return match(normalize(trimmed)) ?? trimmed
    }

    // MARK: Matching

    /// Lowercased, with hyphens and slashes turned into spaces and runs of
    /// whitespace collapsed — so "Semi-Finals", "semi finals" and
    /// "Semi  Final" all reduce to "semi finals"/"semi final".
    private static func normalize(_ value: String) -> String {
        let separatorsFlattened = value.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "/", with: " ")
        return separatorsFlattened
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    /// Order matters throughout: "group semi final" also contains "semi
    /// final", which in turn contains "final", so the most specific test has
    /// to come first.
    private static func match(_ text: String) -> String? {
        // Qualifiers. Checked before the "final" family because a string like
        // "Pre-Qualifier" must never fall through to something else.
        if text.contains("pre qualif")            { return L10n.Round.preQualifier }
        if text.hasPrefix("qualifier"), let n = firstNumber(in: text) {
            return L10n.Round.qualifierN(n)
        }

        // The knockout ladder.
        if text.contains("group semi")            { return L10n.Round.groupSemiFinal }
        if text.contains("semi")                  { return L10n.Round.semiFinal }
        if text.contains("quarter")               { return L10n.Round.quarterFinal }
        if text.contains("group final")           { return L10n.Round.groupFinal }
        if text.contains("final")                 { return L10n.Round.final }

        // "Last 16", "Last 32".
        if text.hasPrefix("last"), let n = firstNumber(in: text) {
            return L10n.Round.lastN(n)
        }

        // Round robin before numbered rounds — "round robin" has no digits,
        // but keeping it here documents the precedence.
        if text.contains("round robin")           { return L10n.Round.roundRobin }
        if text.hasPrefix("round"), let n = firstNumber(in: text) {
            return L10n.Round.roundN(n)
        }

        // League phase, optionally qualified by stage and week:
        // "League Phase (STAGE ONE / WEEK 2)".
        if text.contains("league phase") {
            guard let detail = stageAndWeek(text) else { return L10n.Round.leaguePhase }
            return "\(L10n.Round.leaguePhase) (\(detail))"
        }

        if text.contains("group stage")           { return L10n.Round.groupStage }

        // Bare "Stage One" / "Stage 2" / "Stage One/WK1".
        if text.contains("stage") {
            return stageAndWeek(text)
        }

        return nil
    }

    /// "Stage 1 / Week 2" from whichever of the two the string carries, or nil
    /// when it carries neither. Both spellings feed this, so a bare
    /// "Stage One/WK1" keeps its week instead of collapsing to "Stage 1".
    private static func stageAndWeek(_ text: String) -> String? {
        let parts = [
            stageNumber(in: text).map(L10n.Round.stageN),
            weekNumber(in: text).map(L10n.Round.weekN)
        ].compactMap { $0 }

        return parts.isEmpty ? nil : parts.joined(separator: " / ")
    }

    // MARK: Parsing

    private static func firstNumber(in text: String) -> Int? {
        let digits = text.drop { !$0.isNumber }.prefix { $0.isNumber }
        return Int(digits)
    }

    /// Stage numbers come as words ("STAGE ONE") or digits ("Stage 2"), and
    /// sometimes both spellings appear in the same feed.
    private static func stageNumber(in text: String) -> Int? {
        guard let range = text.range(of: "stage ") else { return nil }
        let remainder = text[range.upperBound...]

        let wordValues = ["one": 1, "two": 2, "three": 3, "four": 4]
        for (word, value) in wordValues where remainder.hasPrefix(word) {
            return value
        }
        return Int(remainder.prefix { $0.isNumber })
    }

    /// Weeks appear as "WEEK 2" or abbreviated "WK2".
    private static func weekNumber(in text: String) -> Int? {
        for marker in ["week ", "week", "wk"] {
            guard let range = text.range(of: marker) else { continue }
            if let value = Int(text[range.upperBound...].prefix { $0.isNumber }) {
                return value
            }
        }
        return nil
    }

    /// Returns the round name with a trailing "(held over)" removed, or nil
    /// when there isn't one. Tolerates "Held Over", "held over" and "heldover".
    private static func heldOverBase(of value: String) -> String? {
        guard let open = value.lastIndex(of: "("),
              value.hasSuffix(")") else { return nil }

        let inside = normalize(String(value[value.index(after: open)...].dropLast()))
        guard inside == "held over" || inside == "heldover" else { return nil }

        let base = value[..<open].trimmingCharacters(in: .whitespaces)
        return base.isEmpty ? nil : base
    }
}
