//
//  PlayerMatchDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import Foundation

/// Oyuncunun son maçları için DTO
/// get_latest_matches RPC fonksiyonundan dönen veri yapısı
struct PlayerMatchDTO: Decodable {
    let tournamentId: String
    let tournamentName: String
    let tournamentSeason: Int
    let matchId: String
    let round: String
    let status: String
    let startDateTime: String?
    let homePlayerId: String
    let awayPlayerId: String?
    let homePlayerScore: Int?
    let awayPlayerScore: Int?
    let homePlayer: PlayerDTO
    let awayPlayer: PlayerDTO?
    
    enum CodingKeys: String, CodingKey {
        case tournamentId
        case tournamentName
        case tournamentSeason
        case matchId
        case round
        case status
        case startDateTime
        case homePlayerId
        case awayPlayerId
        case homePlayerScore
        case awayPlayerScore
        case homePlayer
        case awayPlayer
    }
}

// MARK: - Computed Properties

extension PlayerMatchDTO {
    /// Both home and away players are TBD (firstName is nil or empty)
    var hasBothPlayersTBD: Bool {
        let homeIsTBD = homePlayer.firstName == nil || homePlayer.firstName?.isEmpty == true
        let awayIsTBD = awayPlayer == nil || awayPlayer?.firstName == nil || awayPlayer?.firstName?.isEmpty == true
        return homeIsTBD && awayIsTBD
    }
}

// MARK: - Preview Data

#if DEBUG
extension PlayerMatchDTO {
    static let preview = PlayerMatchDTO(
        tournamentId: "cb7d365d-cc23-4dd1-b09f-9d9ed3560446",
        tournamentName: "World Championship",
        tournamentSeason: 2025,
        matchId: "match-001",
        round: "Final",
        status: "Finished",
        startDateTime: "2025-05-05T14:00:00Z",
        homePlayerId: "player-001",
        awayPlayerId: "player-002",
        homePlayerScore: 18,
        awayPlayerScore: 15,
        homePlayer: .preview,
        awayPlayer: PlayerDTO(
            firstName: "Judd",
            surname: "Trump",
            country: "ENG",
            countryCode: "gb-eng",
            dob: "1989-08-20",
            turnedPro: 2005,
            photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg",
            rank: 2
        )
    )
    
    static let previewList: [PlayerMatchDTO] = [
        preview,
        PlayerMatchDTO(
            tournamentId: "tour-002",
            tournamentName: "UK Championship",
            tournamentSeason: 2024,
            matchId: "match-002",
            round: "Semi Final",
            status: "Finished",
            startDateTime: "2024-12-07T19:00:00Z",
            homePlayerId: "player-001",
            awayPlayerId: "player-003",
            homePlayerScore: 6,
            awayPlayerScore: 4,
            homePlayer: .preview,
            awayPlayer: PlayerDTO(
                firstName: "Mark",
                surname: "Selby",
                country: "ENG",
                countryCode: "gb-eng",
                dob: "1983-06-19",
                turnedPro: 1999,
                photoUrl: nil,
                rank: 3
            )
        )
    ]
}
#endif
