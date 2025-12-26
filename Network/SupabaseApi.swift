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
    static func fetchLiveMatches() async throws -> [MatchDTO] {
        let response: [MatchDTO] = try await client
            .rpc("get_live_matches")
            .execute()
            .value
        return response
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
