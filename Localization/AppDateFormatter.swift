//
//  AppDateFormatter.swift
//  Snooker
//
//  Two kinds of date formatting, kept deliberately separate because mixing
//  them up is the classic localization bug:
//
//  * `parser(_:)`  — reads machine dates from the backend ("2026-04-18").
//    Pinned to en_US_POSIX so it keeps working on a device set to a
//    non-Gregorian calendar or non-Latin digits, where a locale-sensitive
//    formatter would simply return nil.
//
//  * `display(_:)` — writes dates for the user. Follows the app language, and
//    takes a *template* rather than a format, so field order and separators
//    rearrange per language ("18 Apr" in English, "4月18日" in Chinese)
//    instead of being frozen into an English-shaped pattern.
//

import Foundation

nonisolated enum AppDateFormatter {

    // MARK: Parsing

    /// Fixed-format parser for backend dates. Never use for display.
    static func parser(_ format: String) -> DateFormatter {
        cached(key: "parse\u{0}\(format)") {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = format
            return formatter
        }
    }

    // MARK: Display

    /// Formatter for a date shown to the user.
    ///
    /// `template` is a skeleton of the fields you want, not a literal pattern:
    /// "dMMM" means day and abbreviated month *in whatever order the language
    /// uses*. Use "j" for the hour so 12- and 24-hour clocks both come out
    /// right.
    static func display(_ template: String) -> DateFormatter {
        let locale = LanguageManager.shared.locale
        return cached(key: "display\u{0}\(locale.identifier)\u{0}\(template)") {
            let formatter = DateFormatter()
            formatter.locale = locale
            formatter.setLocalizedDateFormatFromTemplate(template)
            return formatter
        }
    }

    /// Common templates, named so call sites read as intent rather than as
    /// cryptic skeleton strings.
    enum Template {
        /// "18 Apr" — day and short month.
        static let dayShortMonth = "dMMM"
        /// "18 April 2026" — a full date, e.g. a date of birth.
        static let fullDate = "dMMMMy"
        /// "18 Apr 2026".
        static let dayShortMonthYear = "dMMMy"
        /// "Apr" — month on its own, for a date badge.
        static let shortMonth = "MMM"
        /// "18" — day on its own.
        static let dayOfMonth = "d"
        /// "2026".
        static let year = "y"
        /// "14:30" or "2:30 PM", whichever the language uses.
        static let time = "jm"
    }

    // MARK: Cache
    //
    // These are built inside cell configuration, where allocating a
    // DateFormatter per call is measurably slow. Display formatters are keyed
    // by locale, so a language change simply misses the cache rather than
    // handing back a stale formatter.

    private static let lock = NSLock()
    /// `nonisolated(unsafe)` because the safety comes from `lock`, which the
    /// compiler can't see. Every access below is inside it.
    private nonisolated(unsafe) static var cache: [String: DateFormatter] = [:]

    private static func cached(key: String, make: () -> DateFormatter) -> DateFormatter {
        lock.lock()
        defer { lock.unlock() }
        if let existing = cache[key] { return existing }
        let formatter = make()
        cache[key] = formatter
        return formatter
    }
}
