//
//  HeadToHeadDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import Foundation

struct HeadToHeadDTO: Decodable {
    let matchId: String
    let tournamentId: String
    let tournamentName: String
    let tournamentSeason: Int
    let round: String
    let startDateTime: Date?
    let homePlayerId: String
    let homePlayer: PlayerDTO
    let homeScore: Int
    let awayPlayerId: String
    let awayPlayer: PlayerDTO
    let awayScore: Int
    
    enum CodingKeys: String, CodingKey {
        case matchId
        case tournamentId
        case tournamentName
        case tournamentSeason
        case round
        case startDateTime
        case homePlayerId
        case homePlayer
        case homeScore
        case awayPlayerId
        case awayPlayer
        case awayScore
    }
}
