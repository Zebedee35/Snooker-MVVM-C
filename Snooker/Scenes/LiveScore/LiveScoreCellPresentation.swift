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
    let homePlayerCountry: String?
    let homePlayerDob: String?
    let homePlayerTurnedPro: Int?
    
    let awayPlayerId: String
    let awayPlayerName: String
    let awayPlayerSurname: String
    let awayPlayerPhotoUrl: String?
    let awayPlayerScore: Int
    let awayPlayerFlag: String?
    let awayPlayerRank: Int?
    let awayPlayerCountry: String?
    let awayPlayerDob: String?
    let awayPlayerTurnedPro: Int?
    
    let matchStatus: String
    let round: String
    let tournamentName: String?
    let startDateTime: String?
    let frames: [LiveMatchFrameDTO]

    /// Maç planlanmış mı (henüz başlamamış)?
    var isScheduled: Bool {
        matchStatus.lowercased() == "scheduled"
    }

    /// The in-progress frame's live points, if a frame is currently being
    /// played (shown as "Frame N · x-y" under the score). nil when scheduled,
    /// between frames, or completed.
    var currentFrame: (number: Int, home: Int, away: Int)? {
        let status = matchStatus.lowercased()
        guard status == "live" || status == "break" || status == "suspended" else { return nil }
        // The frame in play is the last one once it exceeds the frames already won.
        guard frames.count > (homePlayerScore + awayPlayerScore), let last = frames.last else { return nil }
        return (last.frameNumber, last.homePlayerPoints ?? 0, last.awayPlayerPoints ?? 0)
    }
    
    /// Home oyuncunun kısaltılmış adı
    /// Çinli: "Ding J.", Diğer: "J. Trump"
    var homePlayerShortName: String {
        PlayerNameHelper.shortenedName(firstName: homePlayerName, surname: homePlayerSurname, flagEmoji: homePlayerFlag)
    }
    
    /// Away oyuncunun kısaltılmış adı
    /// Çinli: "Ding J.", Diğer: "J. Trump"
    var awayPlayerShortName: String {
        PlayerNameHelper.shortenedName(firstName: awayPlayerName, surname: awayPlayerSurname, flagEmoji: awayPlayerFlag)
    }
    
    /// Scheduled maçlar için formatlanmış başlangıç zamanı
    /// Bugün ise: "14:00", farklı gün ise: "2 Dec / 14:00"
    var formattedStartTime: String? {
        guard let dateString = startDateTime else { return nil }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Fractional seconds olmadan da dene
        var date = isoFormatter.date(from: dateString)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }
        
        guard let matchDate = date else { return nil }
        
        let calendar = Calendar.current
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.timeZone = TimeZone.current
        
        if calendar.isDateInToday(matchDate) {
            // Bugün - sadece saat
            timeFormatter.dateFormat = "HH:mm"
            return timeFormatter.string(from: matchDate)
        } else {
            // Farklı gün - tarih ilk satır, saat ikinci satır
            timeFormatter.dateFormat = "d MMM"
            let datePart = timeFormatter.string(from: matchDate)
            timeFormatter.dateFormat = "HH:mm"
            let timePart = timeFormatter.string(from: matchDate)
            return "\(datePart)\n\(timePart)"
        }
    }
    
    /// Scheduled maçlar için sadece tarih kısmı (bugünse nil döner)
    var formattedDatePart: String? {
        guard let dateString = startDateTime else { return nil }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = isoFormatter.date(from: dateString)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }
        
        guard let matchDate = date else { return nil }
        
        let calendar = Calendar.current
        if calendar.isDateInToday(matchDate) {
            return nil // Bugün ise tarih gösterme
        }
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.dateFormat = "d MMM"
        return timeFormatter.string(from: matchDate)
    }
    
    /// Scheduled maçlar için sadece saat kısmı
    var formattedTimePart: String? {
        guard let dateString = startDateTime else { return nil }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var date = isoFormatter.date(from: dateString)
        if date == nil {
            isoFormatter.formatOptions = [.withInternetDateTime]
            date = isoFormatter.date(from: dateString)
        }
        
        guard let matchDate = date else { return nil }
        
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale.current
        timeFormatter.timeZone = TimeZone.current
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: matchDate)
    }
    
    // MARK: - Initialization
    
    init(match: MatchDTO) {
        self.matchId = match.id
        
        self.homePlayerId = match.homePlayerId ?? ""
        self.homePlayerName = match.homePlayer.firstName ?? "TBD"
        self.homePlayerSurname = match.homePlayer.surname ?? ""
        self.homePlayerPhotoUrl = match.homePlayer.photoUrl
        self.homePlayerScore = match.homePlayerScore ?? 0
        self.homePlayerFlag = CountryFlagHelper.flagEmoji(for: match.homePlayer.countryCode)
        self.homePlayerRank = match.homePlayer.rank
        self.homePlayerCountry = match.homePlayer.country
        self.homePlayerDob = match.homePlayer.dob
        self.homePlayerTurnedPro = match.homePlayer.turnedPro
        
        self.awayPlayerId = match.awayPlayerId ?? ""
        self.awayPlayerName = match.awayPlayer.firstName ?? "TBD"
        self.awayPlayerSurname = match.awayPlayer.surname ?? ""
        self.awayPlayerPhotoUrl = match.awayPlayer.photoUrl
        self.awayPlayerScore = match.awayPlayerScore ?? 0
        self.awayPlayerFlag = CountryFlagHelper.flagEmoji(for: match.awayPlayer.countryCode)
        self.awayPlayerRank = match.awayPlayer.rank
        self.awayPlayerCountry = match.awayPlayer.country
        self.awayPlayerDob = match.awayPlayer.dob
        self.awayPlayerTurnedPro = match.awayPlayer.turnedPro
        
        self.matchStatus = match.status
        self.round = match.round
        self.tournamentName = match.tournamentName
        self.startDateTime = match.startDateTime
        self.frames = match.frames ?? []
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
        homePlayerCountry: String? = nil,
        homePlayerDob: String? = nil,
        homePlayerTurnedPro: Int? = nil,
        awayPlayerId: String = UUID().uuidString,
        awayPlayerName: String,
        awayPlayerSurname: String,
        awayPlayerPhotoUrl: String?,
        awayPlayerScore: Int,
        awayPlayerFlag: String?,
        awayPlayerRank: Int?,
        awayPlayerCountry: String? = nil,
        awayPlayerDob: String? = nil,
        awayPlayerTurnedPro: Int? = nil,
        matchStatus: String,
        round: String,
        tournamentName: String? = nil,
        startDateTime: String? = nil,
        frames: [LiveMatchFrameDTO] = []
    ) {
        self.matchId = matchId
        self.homePlayerId = homePlayerId
        self.homePlayerName = homePlayerName
        self.homePlayerSurname = homePlayerSurname
        self.homePlayerPhotoUrl = homePlayerPhotoUrl
        self.homePlayerScore = homePlayerScore
        self.homePlayerFlag = homePlayerFlag
        self.homePlayerRank = homePlayerRank
        self.homePlayerCountry = homePlayerCountry
        self.homePlayerDob = homePlayerDob
        self.homePlayerTurnedPro = homePlayerTurnedPro
        self.awayPlayerId = awayPlayerId
        self.awayPlayerName = awayPlayerName
        self.awayPlayerSurname = awayPlayerSurname
        self.awayPlayerPhotoUrl = awayPlayerPhotoUrl
        self.awayPlayerScore = awayPlayerScore
        self.awayPlayerFlag = awayPlayerFlag
        self.awayPlayerRank = awayPlayerRank
        self.awayPlayerCountry = awayPlayerCountry
        self.awayPlayerDob = awayPlayerDob
        self.awayPlayerTurnedPro = awayPlayerTurnedPro
        self.matchStatus = matchStatus
        self.round = round
        self.tournamentName = tournamentName
        self.startDateTime = startDateTime
        self.frames = frames
    }
    
    // MARK: - Match Detail

    func matchDetailPresentation() -> MatchDetailPresentation {
        MatchDetailPresentation(
            matchId: matchId,
            homePlayerId: homePlayerId,
            homePlayerName: homePlayerName,
            homePlayerSurname: homePlayerSurname,
            homePlayerPhotoUrl: homePlayerPhotoUrl,
            homePlayerFlag: homePlayerFlag,
            homePlayerScore: homePlayerScore,
            awayPlayerId: awayPlayerId,
            awayPlayerName: awayPlayerName,
            awayPlayerSurname: awayPlayerSurname,
            awayPlayerPhotoUrl: awayPlayerPhotoUrl,
            awayPlayerFlag: awayPlayerFlag,
            awayPlayerScore: awayPlayerScore,
            status: matchStatus,
            round: round,
            tournamentName: tournamentName,
            startDateTime: startDateTime,
            frames: frames.map(MatchDetailFrame.init(dto:))
        )
    }

    // MARK: - Player Detail Helpers

    func homePlayerDetailPresentation() -> PlayerDetailPresentation {
        PlayerDetailPresentation(
            playerId: homePlayerId,
            firstName: homePlayerName,
            surname: homePlayerSurname,
            photoUrl: homePlayerPhotoUrl,
            flagEmoji: homePlayerFlag,
            country: homePlayerCountry,
            rank: homePlayerRank,
            dob: homePlayerDob,
            turnedPro: homePlayerTurnedPro
        )
    }
    
    func awayPlayerDetailPresentation() -> PlayerDetailPresentation {
        PlayerDetailPresentation(
            playerId: awayPlayerId,
            firstName: awayPlayerName,
            surname: awayPlayerSurname,
            photoUrl: awayPlayerPhotoUrl,
            flagEmoji: awayPlayerFlag,
            country: awayPlayerCountry,
            rank: awayPlayerRank,
            dob: awayPlayerDob,
            turnedPro: awayPlayerTurnedPro
        )
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
    
    /// Scheduled maç preview - farklı gün
    static let previewScheduled = LiveScoreCellPresentation(
        homePlayerName: "Neil",
        homePlayerSurname: "Robertson",
        homePlayerPhotoUrl: nil,
        homePlayerScore: 0,
        homePlayerFlag: "🇦🇺",
        homePlayerRank: 5,
        awayPlayerName: "Kyren",
        awayPlayerSurname: "Wilson",
        awayPlayerPhotoUrl: nil,
        awayPlayerScore: 0,
        awayPlayerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
        awayPlayerRank: 6,
        matchStatus: "Scheduled",
        round: "Quarter Final",
        startDateTime: "2024-12-26T14:00:00Z"
    )
    
    /// Scheduled maç preview - bugün
    static let previewScheduledToday = LiveScoreCellPresentation(
        homePlayerName: "John",
        homePlayerSurname: "Higgins",
        homePlayerPhotoUrl: nil,
        homePlayerScore: 0,
        homePlayerFlag: "🏴󠁧󠁢󠁳󠁣󠁴󠁿",
        homePlayerRank: 8,
        awayPlayerName: "Mark",
        awayPlayerSurname: "Williams",
        awayPlayerPhotoUrl: nil,
        awayPlayerScore: 0,
        awayPlayerFlag: "🏴󠁧󠁢󠁷󠁬󠁳󠁿",
        awayPlayerRank: 9,
        matchStatus: "Scheduled",
        round: "Quarter Final",
        startDateTime: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
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
        // Scheduled maç - farklı gün (26 Dec 14:00)
        LiveScoreCellPresentation(
            homePlayerName: "Neil",
            homePlayerSurname: "Robertson",
            homePlayerPhotoUrl: nil,
            homePlayerScore: 0,
            homePlayerFlag: "🇦🇺",
            homePlayerRank: 5,
            awayPlayerName: "Kyren",
            awayPlayerSurname: "Wilson",
            awayPlayerPhotoUrl: nil,
            awayPlayerScore: 0,
            awayPlayerFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            awayPlayerRank: 6,
            matchStatus: "Scheduled",
            round: "Quarter Final",
            startDateTime: "2024-12-26T14:00:00Z"
        ),
        // Scheduled maç - bugün (sadece saat gösterir)
        LiveScoreCellPresentation(
            homePlayerName: "John",
            homePlayerSurname: "Higgins",
            homePlayerPhotoUrl: nil,
            homePlayerScore: 0,
            homePlayerFlag: "🏴󠁧󠁢󠁳󠁣󠁴󠁿",
            homePlayerRank: 8,
            awayPlayerName: "Mark",
            awayPlayerSurname: "Williams",
            awayPlayerPhotoUrl: nil,
            awayPlayerScore: 0,
            awayPlayerFlag: "🏴󠁧󠁢󠁷󠁬󠁳󠁿",
            awayPlayerRank: 9,
            matchStatus: "Scheduled",
            round: "Quarter Final",
            startDateTime: ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)) // 1 saat sonra
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
