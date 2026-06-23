//
//  BracketModels.swift
//  Snooker
//
//  Turns a tournament's matches into ordered bracket columns using
//  `fixture_number`, which encodes the draw position. See BracketViewController
//  for how columns are laid out and connected.
//

import Foundation

struct BracketMatch {
    let id: String
    let round: String
    let fixtureNumber: Int
    let homeName: String
    let awayName: String
    let homeScore: Int?
    let awayScore: Int?
    let homeIsWinner: Bool
    let awayIsWinner: Bool
}

enum BracketBuilder {

    /// Group matches into rounds (left→right columns), ordered by fixture number.
    /// Matches without a `fixtureNumber` can't be placed and are skipped.
    static func buildColumns(from matches: [MatchDTO]) -> [[BracketMatch]] {
        let placeable: [(fixture: Int, dto: MatchDTO)] = matches.compactMap { dto in
            guard let fixture = dto.fixtureNumber else { return nil }
            return (fixture, dto)
        }
        guard !placeable.isEmpty else { return [] }

        var byRound: [String: [(fixture: Int, dto: MatchDTO)]] = [:]
        for item in placeable {
            byRound[item.dto.round, default: []].append(item)
        }

        // Rounds are ordered by their smallest fixture number (Round 1 first …).
        let orderedRoundNames = byRound.keys.sorted { lhs, rhs in
            let lMin = byRound[lhs]?.map(\.fixture).min() ?? .max
            let rMin = byRound[rhs]?.map(\.fixture).min() ?? .max
            return lMin < rMin
        }

        return orderedRoundNames.map { roundName in
            (byRound[roundName] ?? [])
                .sorted { $0.fixture < $1.fixture }
                .map { makeMatch(fixture: $0.fixture, dto: $0.dto) }
        }
    }

    private static func makeMatch(fixture: Int, dto: MatchDTO) -> BracketMatch {
        let isCompleted = ["completed", "finished"].contains(dto.status.lowercased())
        var homeWin = false
        var awayWin = false
        if isCompleted, let home = dto.homePlayerScore, let away = dto.awayPlayerScore, home != away {
            homeWin = home > away
            awayWin = away > home
        }

        return BracketMatch(
            id: dto.id,
            round: dto.round,
            fixtureNumber: fixture,
            homeName: displayName(dto.homePlayer),
            awayName: displayName(dto.awayPlayer),
            homeScore: dto.homePlayerScore,
            awayScore: dto.awayPlayerScore,
            homeIsWinner: homeWin,
            awayIsWinner: awayWin
        )
    }

    private static func displayName(_ player: PlayerDTO) -> String {
        let first = player.firstName ?? ""
        let last = player.surname ?? ""
        if first.isEmpty && last.isEmpty { return "TBD" }
        return PlayerNameHelper.shortenedName(
            firstName: player.firstName,
            surname: player.surname,
            flagEmoji: player.flagEmoji
        )
    }
}
