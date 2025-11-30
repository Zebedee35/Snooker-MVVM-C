//
//  HomeCellPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import Foundation

// MARK: - Round Type

/// Maç round türleri - Final ve Semi Final için büyük cell kullanılır
enum RoundType: Equatable {
    case final
    case semiFinal
    case other
    
    /// Bu round için büyük cell (LiveScoreCell) kullanılmalı mı?
    var usesBigCell: Bool {
        switch self {
        case .final, .semiFinal:
            return true
        case .other:
            return false
        }
    }
    
    /// String'den RoundType oluştur
    static func from(_ string: String) -> RoundType {
        let lowercased = string.lowercased()
        if lowercased.contains("final") && !lowercased.contains("semi") && !lowercased.contains("quarter") {
            return .final
        } else if lowercased.contains("semi") {
            return .semiFinal
        }
        return .other
    }
    
    /// Sıralama için öncelik değeri (düşük = daha önemli/yukarıda)
    var sortOrder: Int {
        switch self {
        case .final: return 0
        case .semiFinal: return 1
        case .other: return 2
        }
    }
}

// MARK: - Match Section

/// Section için model - round adı ve maçlar
struct MatchSection {
    let roundName: String
    let roundType: RoundType
    let matches: [HomeCellPresentation]
}

// MARK: - Home Cell Presentation

/// Her maç için UI presentation modeli
struct HomeCellPresentation {
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
    
    let status: String
    let round: String
    let roundType: RoundType
    let startDateTime: String?
    
    /// Bu maç için büyük cell kullanılmalı mı?
    var usesBigCell: Bool {
        roundType.usesBigCell
    }
    
    /// Maç canlı mı?
    var isLive: Bool {
        status.lowercased() == "live"
    }
    
    /// LiveScoreCell için presentation dönüşümü
    var toLiveScoreCellPresentation: LiveScoreCellPresentation {
        LiveScoreCellPresentation(
            homePlayerName: homePlayerName,
            homePlayerSurname: homePlayerSurname,
            homePlayerPhotoUrl: homePlayerPhotoUrl,
            homePlayerScore: homePlayerScore,
            homePlayerFlag: homePlayerFlag,
            homePlayerRank: homePlayerRank,
            awayPlayerName: awayPlayerName,
            awayPlayerSurname: awayPlayerSurname,
            awayPlayerPhotoUrl: awayPlayerPhotoUrl,
            awayPlayerScore: awayPlayerScore,
            awayPlayerFlag: awayPlayerFlag,
            awayPlayerRank: awayPlayerRank,
            matchStatus: status,
            round: round
        )
    }
    
    // MARK: - Initialization
    
    init(match: MatchDTO) {
        self.matchId = match.id
        
        self.homePlayerId = match.homePlayerId
        self.homePlayerName = match.homePlayer.firstName
        self.homePlayerSurname = match.homePlayer.surname
        self.homePlayerPhotoUrl = match.homePlayer.photoUrl
        self.homePlayerScore = match.homePlayerScore ?? 0
        self.homePlayerFlag = match.homePlayer.flagEmoji
        self.homePlayerRank = match.homePlayer.rank
        
        self.awayPlayerId = match.awayPlayerId
        self.awayPlayerName = match.awayPlayer.firstName
        self.awayPlayerSurname = match.awayPlayer.surname
        self.awayPlayerPhotoUrl = match.awayPlayer.photoUrl
        self.awayPlayerScore = match.awayPlayerScore ?? 0
        self.awayPlayerFlag = match.awayPlayer.flagEmoji
        self.awayPlayerRank = match.awayPlayer.rank
        
        self.status = match.status
        self.round = match.round
        self.roundType = RoundType.from(match.round)
        self.startDateTime = match.startDateTime
    }
}
