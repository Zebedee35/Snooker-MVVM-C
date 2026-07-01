//
//  MatchDetailPresentation.swift
//  Snooker
//
//  Drives the per-match detail screen (frame-by-frame breakdown, WST-style).
//

import Foundation

// MARK: - Frame Row

/// One frame's line in the breakdown table.
struct MatchDetailFrame {
    let frameNumber: Int
    let homePoints: Int
    let awayPoints: Int
    /// Highest 50+ break in this frame (0 = none / below 50).
    let homeBreak: Int
    let awayBreak: Int

    var homeWon: Bool { homePoints > awayPoints }
    var awayWon: Bool { awayPoints > homePoints }

    init(dto: LiveMatchFrameDTO) {
        self.frameNumber = dto.frameNumber
        self.homePoints = dto.homePlayerPoints ?? 0
        self.awayPoints = dto.awayPlayerPoints ?? 0
        self.homeBreak = dto.homePlayerFiftyPlusBreaks ?? 0
        self.awayBreak = dto.awayPlayerFiftyPlusBreaks ?? 0
    }
}

// MARK: - Match Detail Presentation

struct MatchDetailPresentation {
    let matchId: String
    let homePlayerId: String
    let homePlayerName: String
    let homePlayerSurname: String
    let homePlayerPhotoUrl: String?
    let homePlayerFlag: String?
    let homePlayerScore: Int

    let awayPlayerId: String
    let awayPlayerName: String
    let awayPlayerSurname: String
    let awayPlayerPhotoUrl: String?
    let awayPlayerFlag: String?
    let awayPlayerScore: Int

    let status: String
    let round: String
    let tournamentName: String?
    let startDateTime: String?
    let frames: [MatchDetailFrame]

    /// Total frames played (the "(4)" in the WST score block).
    var framesPlayed: Int { frames.count }

    var isLive: Bool {
        let s = status.lowercased()
        return s == "live" || s == "break" || s == "suspended"
    }

    /// Status banner text shown above the players.
    var statusText: String {
        switch status.lowercased() {
        case "live":              return "LIVE"
        case "break":             return "ON BREAK"
        case "completed", "finished": return "MATCH COMPLETE"
        case "scheduled":         return "SCHEDULED"
        default:                  return status.uppercased()
        }
    }

    /// Header used to launch the existing Head-to-Head sheet from this screen.
    var headToHeadHeaderPresentation: HeadToHeadHeaderPresentation {
        HeadToHeadHeaderPresentation(
            player1Id: homePlayerId,
            player1Name: homePlayerName,
            player1Surname: homePlayerSurname,
            player1PhotoUrl: homePlayerPhotoUrl,
            player1Flag: homePlayerFlag,
            player2Id: awayPlayerId,
            player2Name: awayPlayerName,
            player2Surname: awayPlayerSurname,
            player2PhotoUrl: awayPlayerPhotoUrl,
            player2Flag: awayPlayerFlag
        )
    }
}
