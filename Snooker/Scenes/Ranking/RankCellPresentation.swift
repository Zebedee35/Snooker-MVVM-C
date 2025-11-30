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
    let position: Int
    let playerName: String
    let playerSurname: String
    let playerPhotoUrl: String?
    let playerFlag: String?
    let prizeMoney: String
    
    // MARK: - Initialization
    
    init(ranking: RankingDTO) {
        self.position = ranking.position
        self.playerName = ranking.player.firstName
        self.playerSurname = ranking.player.surname
        self.playerPhotoUrl = ranking.player.photoUrl
        self.playerFlag = CountryFlagHelper.flagEmoji(for: ranking.player.countryCode)
        
        // Prize money formatla
        if let money = ranking.prizeMoney {
            self.prizeMoney = Self.formatPrizeMoney(money)
        } else {
            self.prizeMoney = "£ 0"
        }
    }
    
    /// Manuel oluşturma için (test/preview amaçlı)
    init(
        position: Int,
        playerName: String,
        playerSurname: String,
        playerPhotoUrl: String?,
        playerFlag: String?,
        prizeMoney: String
    ) {
        self.position = position
        self.playerName = playerName
        self.playerSurname = playerSurname
        self.playerPhotoUrl = playerPhotoUrl
        self.playerFlag = playerFlag
        self.prizeMoney = prizeMoney
    }
    
    // MARK: - Helpers
    
    private static func formatPrizeMoney(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "£ "
        formatter.maximumFractionDigits = 0
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: amount)) ?? "£ 0"
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
