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
    /// True for auto-generated future rounds that don't exist in the data yet.
    let isPlaceholder: Bool
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

        let existing = orderedRoundNames.map { roundName in
            (byRound[roundName] ?? [])
                .sorted { $0.fixture < $1.fixture }
                .map { makeMatch(fixture: $0.fixture, dto: $0.dto) }
        }

        return appendPlaceholderRounds(to: existing)
    }

    /// Extends the bracket with empty future rounds (Round 2 → Final) that
    /// aren't in the data yet, by halving from the most-advanced real round.
    /// Only extends a clean power-of-two knockout so we never invent garbage.
    private static func appendPlaceholderRounds(to columns: [[BracketMatch]]) -> [[BracketMatch]] {
        guard var feeder = columns.last, feeder.count > 1 else { return columns }
        var count = feeder.count
        // Power-of-two check: 16 → 8 → 4 → 2 → 1.
        guard count & (count - 1) == 0 else { return columns }

        var result = columns
        var fixtureSeed = (columns.flatMap { $0 }.map(\.fixtureNumber).max() ?? 0) + 1

        while count > 1 {
            count /= 2
            let name = syntheticRoundName(matchCount: count)
            var round: [BracketMatch] = []
            for i in 0..<count {
                // Winners of completed feeder matches advance into these slots;
                // undecided feeders leave a "TBD". Deeper rounds feed from
                // placeholders (no winner yet) so they stay TBD.
                let home = winnerName(of: feeder[2 * i]) ?? "TBD"
                let away = winnerName(of: feeder[2 * i + 1]) ?? "TBD"
                round.append(BracketMatch(
                    id: "placeholder-\(fixtureSeed)",
                    round: name,
                    fixtureNumber: fixtureSeed,
                    homeName: home,
                    awayName: away,
                    homeScore: nil,
                    awayScore: nil,
                    homeIsWinner: false,
                    awayIsWinner: false,
                    isPlaceholder: true
                ))
                fixtureSeed += 1
            }
            result.append(round)
            feeder = round
        }
        return result
    }

    /// The advancing player's name if the match is decided, else nil.
    private static func winnerName(of match: BracketMatch) -> String? {
        if match.homeIsWinner { return match.homeName }
        if match.awayIsWinner { return match.awayName }
        return nil
    }

    private static func syntheticRoundName(matchCount: Int) -> String {
        switch matchCount {
        case 1: return "Final"
        case 2: return "Semi Finals"
        case 4: return "Quarter Finals"
        case 8: return "Round 2"
        default: return "Last \(matchCount * 2)"
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
            awayIsWinner: awayWin,
            isPlaceholder: false
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
