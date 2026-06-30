//
//  SupabaseApi.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 8.10.2025.
//

import Foundation
import Supabase

// MARK: - Supabase Configuration
struct SupabaseConfig {
  static let projectURL = URL(string: "<PROJECT_URL>")!
  static let apiKey = "<API_KEY>"
}

// MARK: - Supabase Endpoints
enum SupabaseEndpoint: String {
    case seasons = "tournament"
    case matches = "matches"
    case players = "players"
    case rankings = "rankings"
    case tournaments = "tournaments"
    case appAnnouncements = "app_announcements"
    
    var path: String {
        return "/rest/v1/\(self.rawValue)"
    }
}

// MARK: - Supabase API Manager
struct SupabaseAPI {
    // Tek bir client instance'ı oluştur ve her yerde kullan
    static let client: SupabaseClient = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let options = SupabaseClientOptions(
            db: .init(
                schema: "public",
                decoder: decoder
            )
        )
        
        return SupabaseClient(
            supabaseURL: SupabaseConfig.projectURL,
            supabaseKey: SupabaseConfig.apiKey,
            options: options
        )
    }()
    
    // MARK: - Round Priority Order
    
    /// Round sıralama önceliği - düşük index = daha yüksek öncelik (üstte gösterilir)
    private static let roundPriorityOrder: [String] = [
        "Final",
        "Group Final",
        "Semi Final",
        "Semi Finals",
        "Semi-Final",
        "Semi-Finals",
        "Group Semi Finals",
        "Group Semi-Finals",
        "Quarter Final",
        "Quarter Finals",
        "Last 16",
        "Round Robin",
        "Round 6",
        "Round 5",
        "Round 4",
        "Round 3",
        "Round 2",
        "Round 1",
        "Round 1 (Held Over)",
        "Round 1 (held over)",
        "Qualifier 1 (heldover)",
        "Qualifier 2 (heldover)",
        "Pre-Qualifier",
        "Group Stage",
        "League Phase",
        "League Phase (STAGE ONE / WEEK 1)",
        "League Phase (STAGE ONE / WEEK 2)",
        "League Phase (STAGE ONE / WEEK 3)",
        "League Phase (STAGE THREE)",
        "League Phase (STAGE TWO / WEEK 1)",
        "League Phase (STAGE TWO / WEEK 2)",
        "Stage 2",
        "Stage 3",
        "Stage One",
        "Stage One/week 2",
        "Stage One/week 3",
        "Stage One/WK1",
        "Stage One/WK2",
        "Stage One/WK3",
        "Stage Three",
        "Stage Two"
    ]
    
    /// Round için priority değeri döndürür (düşük = yüksek öncelik)
    private static func roundPriority(for round: String) -> Int {
        if let index = roundPriorityOrder.firstIndex(of: round) {
            return index
        }
        // Bilinmeyen round'lar en sona
        return Int.max
    }
    
    /// Maçları round önceliğine ve tarihine göre sıralar
    private static func sortMatches(_ matches: [MatchDTO]) -> [MatchDTO] {
        return matches.sorted { match1, match2 in
            let priority1 = roundPriority(for: match1.round)
            let priority2 = roundPriority(for: match2.round)
            
            // Önce round önceliğine göre sırala
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // Aynı round'da ise startDateTime'a göre sırala (büyük tarih üstte)
            let date1 = match1.startDateTime ?? ""
            let date2 = match2.startDateTime ?? ""
            return date1 > date2
        }
    }
    
    // MARK: - Helper Methods

    /// Yeni seasons tablosundan veri çeker.
    /// SQL karşılığı: select * from seasons order by name desc
    static func fetchSeasonsTableRows() async throws -> [SeasonsDTO] {
        let response: [SeasonsDTO] = try await client
            .from("seasons")
            .select(SeasonsDTO.sqlFields)
            .order("name", ascending: false)
            .execute()
            .value
        return response
    }
    
    /// Belirli bir sezonun turnuvalarını çek
    static func fetchTournaments(seasonId: Int) async throws -> [TournamentDTO] {
        return try await client
            .from(SupabaseEndpoint.seasons.rawValue)
            .select(TournamentDTO.sqlFields)
            .eq("season", value: seasonId)
            .order("start_date", ascending: true)
            .execute()
            .value
    }

    /// Seasons tablosundan veri çek
    static func fetchSeasons() async throws -> [TournamentDTO] {
        let response: [TournamentDTO] = try await client
            .from(SupabaseEndpoint.seasons.rawValue)
            .select(TournamentDTO.sqlFields)
            .eq("season", value: 2025)
            .order("start_date", ascending: true)
            .execute()
            .value
        return response
    }
    
    /// Canlı maç verilerini RPC ile cekiyoruz.
    /// RPC canlı maç yokken dizi yerine `null` dönebiliyor; bu durumda boş dizi say.
    static func fetchLiveMatches() async throws -> [MatchDTO] {
        let response: [MatchDTO]? = try await client
            .rpc("get_live_matches")
            .execute()
            .value
        return response ?? []
    }
    
    /// Oyuncu sıralaması verilerini çek
    static func fetchRankings() async throws -> [RankingDTO] {
        let response: [RankingDTO] = try await client
            .from("ranking")
            .select(RankingDTO.sqlFields)
            .order("position", ascending: true)
            .execute()
            .value
        return response
    }

    /// Uygulama genelinde gösterilecek aktif duyuruları çek
    static func fetchActiveAnnouncements() async throws -> [AppAnnouncementDTO] {
        do {
            let response: [AppAnnouncementDTO] = try await client
                .rpc("get_active_announcements")
                .execute()
                .value

            return response
        } catch {
            print("[SupabaseAPI] RPC get_active_announcements failed, falling back to table query: \(error)")

            let fallbackResponse: [AppAnnouncementDTO] = try await client
                .from(SupabaseEndpoint.appAnnouncements.rawValue)
                .select(AppAnnouncementDTO.sqlFields)
                .eq("is_active", value: true)
                .order("display_rank", ascending: false)
                .order("created_at", ascending: false)
                .execute()
                .value

            return fallbackResponse
        }
    }
    
    /// Aktif turnuva veya belirli bir turnuvanın detaylarını maçlarıyla birlikte çek
    /// - Parameter tournamentId: Opsiyonel turnuva ID. Verilmezse aktif turnuva döner.
    /// - Returns: Turnuva bilgisi ve maç listesi (sıralanmış)
    static func fetchTournamentWithMatches(tournamentId: String? = nil) async throws -> TournamentWithMatchesDTO {
        let params: [String: String]
        if let id = tournamentId {
            params = ["tournament_id": id]
        } else {
            params = [:]
        }
        
        let response: TournamentWithMatchesDTO = try await client
            .rpc("get_tournament_with_matches", params: params)
            .single()
            .execute()
            .value
        
        // Maçları sıralayarak yeni DTO döndür
        let sortedMatches = sortMatches(response.matches)
        return TournamentWithMatchesDTO(
            id: response.id,
            name: response.name,
            season: response.season,
            startDate: response.startDate,
            endDate: response.endDate,
            city: response.city,
            venue: response.venue,
            country: response.country,
            matches: sortedMatches
        )
    }
    
    /// Oyuncunun son maçlarını çek
    /// - Parameter playerId: Oyuncu ID
    /// - Returns: Oyuncunun son maçları (en yeni önce)
    static func fetchLatestMatches(playerId: String) async throws -> [PlayerMatchDTO] {
        let params = ["p_player_id": playerId]
        
        let response: [PlayerMatchDTO] = try await client
            .rpc("get_latest_matches", params: params)
            .execute()
            .value
        
        return response
    }
    
    /// İki oyuncu arasındaki head-to-head maç geçmişini çek
    /// - Parameters:
    ///   - player1Id: Birinci oyuncu ID
    ///   - player2Id: İkinci oyuncu ID
    /// - Returns: İki oyuncu arasındaki tüm tamamlanmış maçlar (en yeni önce)
    static func fetchHeadToHead(player1Id: String, player2Id: String) async throws -> [HeadToHeadDTO] {
        let params: [String: String] = [
            "p_player1_id": player1Id,
            "p_player2_id": player2Id
        ]
        
        let response: [HeadToHeadDTO] = try await client
            .rpc("get_head_to_head", params: params)
            .execute()
            .value
        
        return response
    }
    
//    /// Players tablosundan veri çek
//    static func fetchPlayers() async throws -> [Player] {
//        let response: [Player] = try await client
//            .from(SupabaseEndpoint.players.rawValue)
//            .select()
//            .execute()
//            .value
//        return response
//    }
//    
//    /// Matches tablosundan veri çek
//    static func fetchMatches() async throws -> [Match] {
//        let response: [Match] = try await client
//            .from(SupabaseEndpoint.matches.rawValue)
//            .select()
//            .execute()
//            .value
//        return response
//    }
    
    /// Generic select method - herhangi bir tablo için kullanılabilir
    static func select<T: Codable>(
        from endpoint: SupabaseEndpoint,
        responseType: T.Type
    ) async throws -> [T] {
        let response: [T] = try await client
            .from(endpoint.rawValue)
            .select()
            .execute()
            .value
        return response
    }
    
    /// Generic insert method
    static func insert<T: Codable>(
        into endpoint: SupabaseEndpoint,
        data: T
    ) async throws -> T {
        let response: T = try await client
            .from(endpoint.rawValue)
            .insert(data)
            .execute()
            .value
        return response
    }
}
