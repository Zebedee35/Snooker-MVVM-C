//
//  L10n.swift
//  Snooker
//
//  Every user-facing string in the app, in one place.
//
//  Call sites use `L10n.Settings.signOut` rather than a raw key, so a renamed
//  or deleted key is a compile error instead of a string that silently shows
//  its own key at runtime. Keys mirror this structure: `settings.sign_out`.
//
//  Lookups go through LanguageManager, not NSLocalizedString, so the in-app
//  language picker takes effect immediately without a relaunch.
//

import Foundation

// MARK: - Lookup Helpers

/// Plain lookup.
private nonisolated func tr(_ key: String) -> String {
    LanguageManager.shared.string(key)
}

/// Formatted lookup. The locale is passed explicitly so numbers inside the
/// string are grouped the way the *chosen* language expects, and so plural
/// variations from the String Catalog resolve against it.
private nonisolated func tr(_ key: String, _ arguments: CVarArg...) -> String {
    String(
        format: LanguageManager.shared.string(key),
        locale: LanguageManager.shared.locale,
        arguments: arguments
    )
}

// MARK: - Strings

nonisolated enum L10n {

    // MARK: Common

    enum Common {
        static var ok: String            { tr("common.ok") }
        static var cancel: String        { tr("common.cancel") }
        static var error: String         { tr("common.error") }
        /// Stand-in for a player who isn't decided yet ("To Be Determined").
        static var tbd: String           { tr("common.tbd") }
        static var versus: String        { tr("common.versus") }
        /// Generic failure text shown when an error carries no message.
        static var genericError: String  { tr("common.generic_error") }
        /// Inline failure text on an empty screen, carrying the reason.
        static func errorWithReason(_ reason: String) -> String {
            tr("common.error_with_reason", reason)
        }
    }

    // MARK: Tab Bar

    enum Tab {
        static var season: String   { tr("tab.season") }
        static var live: String     { tr("tab.live") }
        static var home: String     { tr("tab.home") }
        static var ranking: String  { tr("tab.ranking") }
        static var settings: String { tr("tab.settings") }
    }

    // MARK: Home

    enum Home {
        static var title: String { tr("home.title") }
        static var empty: String { tr("home.empty") }
    }

    // MARK: Live Scores

    enum Live {
        static var title: String { tr("live.title") }
        static var empty: String { tr("live.empty") }
        /// Badge on an in-progress match. Kept short — it sits in a small pill.
        static var badge: String { tr("live.badge") }
        /// Two-line label: frame number above, that frame's score below.
        static func currentFrame(number: Int, home: Int, away: Int) -> String {
            tr("live.current_frame", number, home, away)
        }
        /// Points scored in the player's current visit to the table. Note this
        /// is a *break* in the snooker sense (a scoring run), unrelated to
        /// `MatchStatus.onBreak`, which means play is paused.
        static func currentBreak(_ points: Int) -> String {
            tr("live.current_break", points)
        }
    }

    // MARK: Rankings

    enum Ranking {
        static var title: String             { tr("ranking.title") }
        static var empty: String             { tr("ranking.empty") }
        static var searchPlaceholder: String { tr("ranking.search_placeholder") }
    }

    // MARK: Seasons

    enum Seasons {
        static var title: String { tr("seasons.title") }
        /// Shown on a tournament date badge when dates aren't announced yet.
        static var dateUnknown: String { tr("seasons.date_unknown") }
    }

    // MARK: Match Status

    enum MatchStatus {
        static var live: String      { tr("match_status.live") }
        static var onBreak: String   { tr("match_status.on_break") }
        static var complete: String  { tr("match_status.complete") }
        static var scheduled: String { tr("match_status.scheduled") }
        static var suspended: String { tr("match_status.suspended") }
        static var completed: String { tr("match_status.completed") }
    }

    // MARK: Match Detail

    enum MatchDetail {
        static var frames: String      { tr("match_detail.frames") }
        static var headToHead: String  { tr("match_detail.head_to_head") }
        static var framesEmpty: String { tr("match_detail.frames_empty") }
        /// Match length, e.g. "Best of 19" — the first to 10 frames wins.
        static func bestOf(_ frames: Int) -> String { tr("match_detail.best_of", frames) }
    }

    // MARK: Tournament

    enum Tournament {
        static var viewBracket: String  { tr("tournament.view_bracket") }
        /// Badge marking a just-added tournament.
        static var newBadge: String     { tr("tournament.new_badge") }
        static var bracketEmpty: String { tr("tournament.bracket_empty") }
    }

    // MARK: Player Detail

    enum Player {
        static var biography: String       { tr("player.biography") }
        static var recentMatches: String   { tr("player.recent_matches") }
        static var noRecentMatches: String { tr("player.no_recent_matches") }
        static var noBiography: String     { tr("player.no_biography") }
        /// Row label preceding a date of birth.
        static var born: String            { tr("player.born") }
        /// Row label preceding the year the player turned professional.
        static var turnedPro: String       { tr("player.turned_pro") }
    }

    // MARK: Head-to-Head

    enum HeadToHead {
        static var allMatches: String { tr("head_to_head.all_matches") }
        static var empty: String      { tr("head_to_head.empty") }
    }

    // MARK: Settings

    enum Settings {
        static var title: String { tr("settings.title") }

        /// Section headers. Displayed uppercased in the UI, but stored in
        /// natural case — uppercasing in code keeps Turkish's dotless i correct
        /// and lets languages that don't uppercase (Chinese) render normally.
        enum Section {
            static var account: String      { tr("settings.section.account") }
            static var support: String      { tr("settings.section.support") }
            static var notification: String { tr("settings.section.notification") }
            static var liveActivity: String { tr("settings.section.live_activity") }
            static var language: String     { tr("settings.section.language") }
            static var other: String        { tr("settings.section.other") }
            static var ourApps: String      { tr("settings.section.our_apps") }
            static var about: String        { tr("settings.section.about") }
            static var developer: String    { tr("settings.section.developer") }
        }

        static var signedIn: String            { tr("settings.signed_in") }
        static var signOut: String             { tr("settings.sign_out") }
        static var deleteAccount: String       { tr("settings.delete_account") }
        static var signInWithApple: String     { tr("settings.sign_in_with_apple") }
        static var supportTheApp: String       { tr("settings.support_the_app") }
        static var language: String            { tr("settings.language") }
        static var darkMode: String            { tr("settings.dark_mode") }
        static var hideTBDMatches: String      { tr("settings.hide_tbd_matches") }
        static var changeAppIcon: String       { tr("settings.change_app_icon") }
        static var announcements: String       { tr("settings.announcements") }
        static var rateUs: String              { tr("settings.rate_us") }
        static var shareApp: String            { tr("settings.share_app") }
        static var giveFeedback: String        { tr("settings.give_feedback") }
        static var sendTestNotification: String { tr("settings.send_test_notification") }

        /// Credit line in the settings footer. The name is passed in so it is
        /// never translated, only the "by".
        static func byAuthor(_ name: String) -> String { tr("settings.by_author", name) }
        static func version(_ version: String) -> String { tr("settings.version", version) }

        /// Our other apps. The app *names* are brands and stay untranslated;
        /// only these one-line descriptions are localized.
        enum OurApps {
            static var filmBoxSubtitle: String     { tr("settings.our_apps.filmbox_subtitle") }
            static var contactNameSubtitle: String { tr("settings.our_apps.contactname_subtitle") }
        }
    }

    // MARK: Notification Preference

    enum NotificationPreference {
        static var allResults: String { tr("notification_preference.all_results") }
        static var mainEvents: String { tr("notification_preference.main_events") }
        static var finalsOnly: String { tr("notification_preference.finals_only") }
        static var none: String       { tr("notification_preference.none") }
    }

    // MARK: Language Picker

    enum Language {
        static var title: String { tr("language.title") }
        /// Option that defers to the device's language setting.
        static var system: String { tr("language.system") }
        /// Subtitle under the System option, naming what it currently resolves
        /// to, e.g. "Currently: English".
        static func systemResolvesTo(_ name: String) -> String {
            tr("language.system_resolves_to", name)
        }
        /// Footer explaining the one thing an in-app switch can't change until
        /// the app is relaunched.
        static var relaunchNote: String { tr("language.relaunch_note") }
        /// Invitation for users to help fix or add translations.
        static var helpTranslate: String { tr("language.help_translate") }
    }

    // MARK: Alerts

    enum Alert {
        enum ChangeAppIcon {
            static var title: String   { tr("alert.change_app_icon.title") }
            static var message: String { tr("alert.change_app_icon.message") }
        }
        enum TestNotification {
            static var title: String   { tr("alert.test_notification.title") }
            static var message: String { tr("alert.test_notification.message") }
        }
        enum SignOut {
            static var title: String   { tr("alert.sign_out.title") }
            static var message: String { tr("alert.sign_out.message") }
        }
        enum DeleteAccount {
            static var title: String    { tr("alert.delete_account.title") }
            static var message: String  { tr("alert.delete_account.message") }
            static var progress: String { tr("alert.delete_account.progress") }
            static var failed: String   { tr("alert.delete_account.failed") }
        }
        static var signInFailed: String { tr("alert.sign_in_failed") }
    }

    // MARK: Edit Profile

    enum EditProfile {
        static var title: String            { tr("edit_profile.title") }
        static var save: String             { tr("edit_profile.save") }
        static var nameSection: String      { tr("edit_profile.name_section") }
        static var nicknameSection: String  { tr("edit_profile.nickname_section") }
        static var namePlaceholder: String  { tr("edit_profile.name_placeholder") }
        static var nicknamePlaceholder: String { tr("edit_profile.nickname_placeholder") }
        /// Hint under the nickname field. Keep the character range as
        /// placeholders — the limits are defined in code, not in the copy.
        static func nicknameHint(min: Int, max: Int) -> String {
            tr("edit_profile.nickname_hint", min, max)
        }
        static var invalidNickname: String { tr("edit_profile.invalid_nickname") }
        static func nicknameLength(min: Int, max: Int) -> String {
            tr("edit_profile.nickname_length", min, max)
        }
        static var nicknameCharacters: String { tr("edit_profile.nickname_characters") }
        static var saveFailed: String         { tr("edit_profile.save_failed") }
    }

    // MARK: Auth

    enum Auth {
        static var notSignedIn: String   { tr("auth.not_signed_in") }
        static var nicknameTaken: String { tr("auth.nickname_taken") }
    }

    // MARK: Tip Jar

    enum TipJar {
        static var title: String        { tr("tip_jar.title") }
        static var heading: String      { tr("tip_jar.heading") }
        static var body: String         { tr("tip_jar.body") }
        static var segmentOneTime: String { tr("tip_jar.segment_one_time") }
        static var segmentMonthly: String { tr("tip_jar.segment_monthly") }
        static var restore: String      { tr("tip_jar.restore") }
        /// Shown on a subscription the user already has.
        static var active: String       { tr("tip_jar.active") }
        static var empty: String        { tr("tip_jar.empty") }
        static var loadFailed: String   { tr("tip_jar.load_failed") }
        static var purchasePending: String { tr("tip_jar.purchase_pending") }
        static var footerMonthly: String   { tr("tip_jar.footer_monthly") }
        static var footerOneTime: String   { tr("tip_jar.footer_one_time") }
        static var termsLink: String    { tr("tip_jar.terms_link") }
        static var privacyLink: String  { tr("tip_jar.privacy_link") }

        enum Thanks {
            static var title: String   { tr("tip_jar.thanks.title") }
            static var message: String { tr("tip_jar.thanks.message") }
            static var dismiss: String { tr("tip_jar.thanks.dismiss") }
        }
        static var errorTitle: String { tr("tip_jar.error_title") }

        /// Billing period shown beside a subscription price ("per month").
        /// Each unit is its own plural-aware key so languages that inflect the
        /// noun by number get it right.
        static func perDay(_ count: Int) -> String   { tr("tip_jar.per_day", count) }
        static func perWeek(_ count: Int) -> String  { tr("tip_jar.per_week", count) }
        static func perMonth(_ count: Int) -> String { tr("tip_jar.per_month", count) }
        static func perYear(_ count: Int) -> String  { tr("tip_jar.per_year", count) }
    }

    // MARK: Announcements

    enum Announcements {
        static var title: String { tr("announcements.title") }
        static var empty: String { tr("announcements.empty") }

        /// Severity labels on an announcement banner.
        enum Kind {
            static var error: String   { tr("announcements.kind.error") }
            static var warning: String { tr("announcements.kind.warning") }
            static var info: String    { tr("announcements.kind.info") }
            static var success: String { tr("announcements.kind.success") }
        }
    }

    // MARK: Rounds
    //
    // Round names arrive from the backend as English strings. RoundName maps
    // them onto these keys; anything unrecognised falls through untranslated.

    enum Round {
        static var final: String            { tr("round.final") }
        static var semiFinal: String        { tr("round.semi_final") }
        static var quarterFinal: String     { tr("round.quarter_final") }
        static var groupFinal: String       { tr("round.group_final") }
        static var groupSemiFinal: String   { tr("round.group_semi_final") }
        static var roundRobin: String       { tr("round.round_robin") }
        static var groupStage: String       { tr("round.group_stage") }
        static var leaguePhase: String      { tr("round.league_phase") }
        static var preQualifier: String     { tr("round.pre_qualifier") }
        /// "Last 16", "Last 32" — the stage with N players remaining.
        static func lastN(_ count: Int) -> String     { tr("round.last_n", count) }
        /// Numbered early rounds: "Round 1", "Round 2".
        static func roundN(_ number: Int) -> String   { tr("round.round_n", number) }
        static func qualifierN(_ number: Int) -> String { tr("round.qualifier_n", number) }
        static func stageN(_ number: Int) -> String   { tr("round.stage_n", number) }
        static func weekN(_ number: Int) -> String    { tr("round.week_n", number) }
        /// Suffix on a match postponed from its original round, e.g.
        /// "Round 1 (Held Over)". Takes the already-localized round name.
        static func heldOver(_ round: String) -> String { tr("round.held_over", round) }
    }
}
