//
//  PlayerMatchCellPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import Foundation

/// Turnuva bazlı maç grubu
struct PlayerMatchSection {
    let tournamentName: String
    let tournamentSeason: Int
    let matches: [PlayerMatchCellPresentation]
    
    var sectionTitle: String {
        "\(tournamentName) \(tournamentSeason)"
    }
}

/// PlayerMatchCell için Presentation modeli
struct PlayerMatchCellPresentation {
    let matchId: String
    let tournamentName: String
    let tournamentSeason: Int
    let round: String
    
    /// Current player ID (PvP ekranı için)
    let currentPlayerId: String
    
    /// Seçili oyuncunun skoru (her zaman solda gösterilecek)
    let currentPlayerScore: Int
    
    /// Rakip oyuncunun ID'si (PvP ekranı için)
    let opponentId: String?
    
    /// Rakip oyuncunun skoru (her zaman sağda gösterilecek)
    let opponentScore: Int
    
    /// Rakip oyuncunun adı
    let opponentName: String
    let opponentSurname: String
    let opponentPhotoUrl: String?
    let opponentFlag: String?
    
    // MARK: - Computed Properties
    
    /// Seçili oyuncu kazandı mı?
    var didCurrentPlayerWin: Bool {
        currentPlayerScore > opponentScore
    }
    
    /// Rakip oyuncunun tam adı
    var opponentFullName: String {
        "\(opponentName) \(opponentSurname)"
    }
    
    // MARK: - Initialization
    
    init(match: PlayerMatchDTO, currentPlayerId: String) {
        self.matchId = match.matchId
        self.tournamentName = match.tournamentName
        self.tournamentSeason = match.tournamentSeason
        self.round = match.round
        self.currentPlayerId = currentPlayerId
        
        let isCurrentPlayerHome = match.homePlayerId == currentPlayerId
        
        if isCurrentPlayerHome {
            // Seçili oyuncu home player
            self.currentPlayerScore = match.homePlayerScore ?? 0
            self.opponentScore = match.awayPlayerScore ?? 0
            self.opponentId = match.awayPlayerId
            self.opponentName = match.awayPlayer?.firstName ?? "TBD"
            self.opponentSurname = match.awayPlayer?.surname ?? ""
            self.opponentPhotoUrl = match.awayPlayer?.photoUrl
            self.opponentFlag = match.awayPlayer?.flagEmoji
        } else {
            // Seçili oyuncu away player
            self.currentPlayerScore = match.awayPlayerScore ?? 0
            self.opponentScore = match.homePlayerScore ?? 0
            self.opponentId = match.homePlayerId
            self.opponentName = match.homePlayer.firstName ?? "TBD"
            self.opponentSurname = match.homePlayer.surname ?? ""
            self.opponentPhotoUrl = match.homePlayer.photoUrl
            self.opponentFlag = match.homePlayer.flagEmoji
        }
    }
}

// MARK: - Preview Data

#if DEBUG
extension PlayerMatchCellPresentation {
    static let preview = PlayerMatchCellPresentation(
        match: .preview,
        currentPlayerId: "player-001"
    )
}
#endif
