//
//  LiveScoreCellPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 25.11.2025.
//

import Foundation

/// LiveScoreCell için ViewModel/Presentation modeli
/// MatchDTO'dan UI'da gösterilecek verilere dönüşümü yapar
struct LiveScoreCellPresentation {
    let matchId: String
    
    let homePlayerId: String
    let homePlayerName: String
    let homePlayerSurname: String
    let homePlayerPhotoUrl: String?
    let homePlayerScore: Int
    let homePlayerFlag: String?
    let homePlayerRank: Int?
    
    let awayPlayerId: String
    let awayPlayerName: String
    let awayPlayerSurname: String
    let awayPlayerPhotoUrl: String?
    let awayPlayerScore: Int
    let awayPlayerFlag: String?
    let awayPlayerRank: Int?
    
    let matchStatus: String
    let round: String
    
    // MARK: - Initialization
    
    init(match: MatchDTO) {
        self.matchId = match.id
        
        self.homePlayerId = match.homePlayerId
        self.homePlayerName = match.homePlayer.firstName
        self.homePlayerSurname = match.homePlayer.surname
        self.homePlayerPhotoUrl = match.homePlayer.photoUrl
        self.homePlayerScore = match.homePlayerScore ?? 0
        self.homePlayerFlag = CountryFlagHelper.flagEmoji(for: match.homePlayer.countryCode)
        self.homePlayerRank = match.homePlayer.rank
        
        self.awayPlayerId = match.awayPlayerId
        self.awayPlayerName = match.awayPlayer.firstName
        self.awayPlayerSurname = match.awayPlayer.surname
        self.awayPlayerPhotoUrl = match.awayPlayer.photoUrl
        self.awayPlayerScore = match.awayPlayerScore ?? 0
        self.awayPlayerFlag = CountryFlagHelper.flagEmoji(for: match.awayPlayer.countryCode)
        self.awayPlayerRank = match.awayPlayer.rank
        
        self.matchStatus = match.status
        self.round = match.round
    }
    
    /// Manuel oluşturma için (test/preview amaçlı)
    init(
        matchId: String = UUID().uuidString,
        homePlayerId: String = UUID().uuidString,
        homePlayerName: String,
        homePlayerSurname: String,
        homePlayerPhotoUrl: String?,
        homePlayerScore: Int,
        homePlayerFlag: String?,
        homePlayerRank: Int?,
        awayPlayerId: String = UUID().uuidString,
        awayPlayerName: String,
        awayPlayerSurname: String,
        awayPlayerPhotoUrl: String?,
        awayPlayerScore: Int,
        awayPlayerFlag: String?,
        awayPlayerRank: Int?,
        matchStatus: String,
        round: String
    ) {
        self.matchId = matchId
        self.homePlayerId = homePlayerId
        self.homePlayerName = homePlayerName
        self.homePlayerSurname = homePlayerSurname
        self.homePlayerPhotoUrl = homePlayerPhotoUrl
        self.homePlayerScore = homePlayerScore
        self.homePlayerFlag = homePlayerFlag
        self.homePlayerRank = homePlayerRank
        self.awayPlayerId = awayPlayerId
        self.awayPlayerName = awayPlayerName
        self.awayPlayerSurname = awayPlayerSurname
        self.awayPlayerPhotoUrl = awayPlayerPhotoUrl
        self.awayPlayerScore = awayPlayerScore
        self.awayPlayerFlag = awayPlayerFlag
        self.awayPlayerRank = awayPlayerRank
        self.matchStatus = matchStatus
        self.round = round
    }
}

// MARK: - Preview Data

#if DEBUG
extension LiveScoreCellPresentation {
    static let preview = LiveScoreCellPresentation(
        homePlayerName: "Ronnie",
        homePlayerSurname: "O'Sullivan",
        homePlayerPhotoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
        homePlayerScore: 18,
        homePlayerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        homePlayerRank: 1,
        awayPlayerName: "Judd",
        awayPlayerSurname: "Trump",
        awayPlayerPhotoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg",
        awayPlayerScore: 14,
        awayPlayerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        awayPlayerRank: 2,
        matchStatus: "Live",
        round: "Final"
    )
    
    static let previewList: [LiveScoreCellPresentation] = [
        preview,
        LiveScoreCellPresentation(
            homePlayerName: "Mark",
            homePlayerSurname: "Selby",
            homePlayerPhotoUrl: "https://35coders.com/common/snooker/img/mselby.jpg",
            homePlayerScore: 6,
            homePlayerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            homePlayerRank: 3,
            awayPlayerName: "Ding",
            awayPlayerSurname: "Junhui",
            awayPlayerPhotoUrl: nil,
            awayPlayerScore: 5,
            awayPlayerFlag: "🇨🇳",
            awayPlayerRank: 15,
            matchStatus: "Live",
            round: "Semi Final"
        ),
        LiveScoreCellPresentation(
            homePlayerName: "Jak",
            homePlayerSurname: "Jones",
            homePlayerPhotoUrl: nil,
            homePlayerScore: 10,
            homePlayerFlag: "🏴󠁧󠁢󠁷󠁬󠁳󠁿",
            homePlayerRank: 24,
            awayPlayerName: "Luca",
            awayPlayerSurname: "Brecel",
            awayPlayerPhotoUrl: "https://35coders.com/common/snooker/img/luca-brecel.jpg",
            awayPlayerScore: 8,
            awayPlayerFlag: "🇧🇪",
            awayPlayerRank: 4,
            matchStatus: "Completed",
            round: "Quarter Final"
        )
    ]
}
#endif
