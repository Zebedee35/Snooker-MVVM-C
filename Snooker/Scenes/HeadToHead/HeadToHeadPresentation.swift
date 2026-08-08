//
//  HeadToHeadPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import Foundation

// MARK: - Header Presentation (İki oyuncu bilgisi)

struct HeadToHeadHeaderPresentation {
    let player1Id: String
    let player1Name: String
    let player1Surname: String
    let player1PhotoUrl: String?
    let player1Flag: String?
    
    let player2Id: String
    let player2Name: String
    let player2Surname: String
    let player2PhotoUrl: String?
    let player2Flag: String?
    
    // Win counts
    var player1Wins: Int = 0
    var player2Wins: Int = 0
    
    var player1FullName: String {
        "\(player1Name) \(player1Surname)"
    }
    
    var player2FullName: String {
        "\(player2Name) \(player2Surname)"
    }
}

// MARK: - Match Cell Presentation

struct HeadToHeadMatchPresentation {
    let matchId: String
    let tournamentName: String
    let tournamentSeason: Int
    let round: String
    let year: String
    
    // Player 1 perspective (always left side)
    let player1Score: Int
    let player2Score: Int
    
    var didPlayer1Win: Bool {
        player1Score > player2Score
    }
    
    var tournamentInfo: String {
        "\(year) - \(tournamentName) - \(round)"
    }
    
    init(dto: HeadToHeadDTO, player1Id: String) {
        self.matchId = dto.matchId
        self.tournamentName = dto.tournamentName
        self.tournamentSeason = dto.tournamentSeason
        self.round = dto.round
        
        // Extract year from startDateTime string or use season
        if let dateString = dto.startDateTime {
            // Parse ISO date string to get year
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            
            var date = isoFormatter.date(from: dateString)
            if date == nil {
                isoFormatter.formatOptions = [.withInternetDateTime]
                date = isoFormatter.date(from: dateString)
            }
            
            if let parsedDate = date {
                let yearFormatter = AppDateFormatter.display(AppDateFormatter.Template.year)
                self.year = yearFormatter.string(from: parsedDate)
            } else {
                self.year = "\(dto.tournamentSeason)"
            }
        } else {
            self.year = "\(dto.tournamentSeason)"
        }
        
        // Determine scores based on player1 position
        if dto.homePlayerId == player1Id {
            self.player1Score = dto.homePlayerScore ?? 0
            self.player2Score = dto.awayPlayerScore ?? 0
        } else {
            self.player1Score = dto.awayPlayerScore ?? 0
            self.player2Score = dto.homePlayerScore ?? 0
        }
    }
}
