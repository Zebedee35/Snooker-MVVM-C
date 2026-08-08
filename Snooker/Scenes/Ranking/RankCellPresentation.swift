//
//  RankCellPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

/// RankCell için Presentation modeli
/// RankingDTO'dan UI'da gösterilecek verilere dönüşümü yapar
struct RankCellPresentation {
    let playerId: String
    let position: Int
    let playerName: String
    let playerSurname: String
    let playerPhotoUrl: String?
    let playerFlag: String?
    let prizeMoney: String
    let playerCountry: String?
    let playerDob: String?
    let playerTurnedPro: Int?
    
    // MARK: - Initialization
    
    init(ranking: RankingDTO) {
        self.playerId = ranking.playerId
        self.position = ranking.position
        self.playerName = ranking.player.firstName ?? L10n.Common.tbd
        self.playerSurname = ranking.player.surname ?? ""
        self.playerPhotoUrl = ranking.player.photoUrl
        self.playerFlag = CountryFlagHelper.flagEmoji(for: ranking.player.countryCode)
        self.playerCountry = ranking.player.country
        self.playerDob = ranking.player.dob
        self.playerTurnedPro = ranking.player.turnedPro
        
        // Prize money formatla
        self.prizeMoney = Self.formatPrizeMoney(ranking.prizeMoney ?? 0)
    }
    
    /// Manuel oluşturma için (test/preview amaçlı)
    init(
        playerId: String = UUID().uuidString,
        position: Int,
        playerName: String,
        playerSurname: String,
        playerPhotoUrl: String?,
        playerFlag: String?,
        prizeMoney: String,
        playerCountry: String? = nil,
        playerDob: String? = nil,
        playerTurnedPro: Int? = nil
    ) {
        self.playerId = playerId
        self.position = position
        self.playerName = playerName
        self.playerSurname = playerSurname
        self.playerPhotoUrl = playerPhotoUrl
        self.playerFlag = playerFlag
        self.prizeMoney = prizeMoney
        self.playerCountry = playerCountry
        self.playerDob = playerDob
        self.playerTurnedPro = playerTurnedPro
    }
    
    // MARK: - Player Detail Helper
    
    func playerDetailPresentation() -> PlayerDetailPresentation {
        PlayerDetailPresentation(
            playerId: playerId,
            firstName: playerName,
            surname: playerSurname,
            photoUrl: playerPhotoUrl,
            flagEmoji: playerFlag,
            country: playerCountry,
            rank: position,
            dob: playerDob,
            turnedPro: playerTurnedPro
        )
    }
    
    // MARK: - Helpers
    
    /// Prize money is genuinely denominated in pounds, so the currency itself
    /// stays GBP in every language — only its *presentation* is localized.
    /// The locale decides the digit grouping and which side the symbol sits on
    /// ("£1,234,567" in English, "1.234.567 £" in German).
    private static func formatPrizeMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = LanguageManager.shared.locale
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
}

// MARK: - Preview Data

#if DEBUG
extension RankCellPresentation {
    static let preview = RankCellPresentation(
        position: 1,
        playerName: "Ronnie",
        playerSurname: "O'Sullivan",
        playerPhotoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
        playerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        prizeMoney: "£ 1,234,500"
    )
    
    static let previewList: [RankCellPresentation] = [
        preview,
        RankCellPresentation(
            position: 2,
            playerName: "Judd",
            playerSurname: "Trump",
            playerPhotoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg",
            playerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            prizeMoney: "£ 1,156,000"
        ),
        RankCellPresentation(
            position: 3,
            playerName: "Mark",
            playerSurname: "Selby",
            playerPhotoUrl: "https://35coders.com/common/snooker/img/mselby.jpg",
            playerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            prizeMoney: "£ 987,250"
        ),
        RankCellPresentation(
            position: 4,
            playerName: "Kyren",
            playerSurname: "Wilson",
            playerPhotoUrl: nil,
            playerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            prizeMoney: "£ 876,500"
        ),
        RankCellPresentation(
            position: 5,
            playerName: "Ding",
            playerSurname: "Junhui",
            playerPhotoUrl: nil,
            playerFlag: "🇨🇳",
            prizeMoney: "£ 654,000"
        )
    ]
}
#endif
