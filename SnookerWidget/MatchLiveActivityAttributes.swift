//
//  MatchLiveActivityAttributes.swift
//  Snooker
//
//  SHARED between the App target AND the Widget Extension target.
//  In Xcode, set Target Membership = [Snooker, SnookerWidgetExtension] for this file.
//
//  ⚠️  The property names in `ContentState` are the JSON keys ActivityKit uses
//      when it decodes a remote push. The Edge Function MUST send a
//      `content-state` object whose keys match these names EXACTLY
//      (ActivityKit uses the default coding keys — camelCase, no snake_case).
//      Keep ContentState small and primitive-typed (Int/String/Bool). Avoid
//      `Date` here: the default JSONEncoder encodes Date as a 2001-reference
//      Double, which is painful to reproduce server-side.
//

import Foundation
import ActivityKit

struct MatchLiveActivityAttributes: ActivityAttributes {

    // MARK: Dynamic data (pushed on every update)
    public struct ContentState: Codable, Hashable {
        /// Frames won by the home player (the big number on the left).
        var homeScore: Int
        /// Frames won by the away player.
        var awayScore: Int
        /// "Live" | "Break" | "Completed" | "Finished" — drives the status pill.
        var status: String
        /// e.g. "Final", "Semi Final".
        var round: String
        /// Points in the current break, if you choose to push it. Optional.
        var currentBreak: Int?
        /// Whose turn it is, for a subtle highlight. nil = unknown.
        /// "home" | "away" | nil
        var atTable: String?
    }

    // MARK: Static data (set once when the activity starts)
    var matchId: String
    var tournamentName: String

    var homeName: String
    var homeFlag: String        // emoji flag, e.g. "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
    var awayName: String
    var awayFlag: String

    /// Frames needed to win the match (best-of). Used for "first to N".
    var framesToWin: Int
}
