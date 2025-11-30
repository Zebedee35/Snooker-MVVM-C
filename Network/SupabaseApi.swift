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
    /// - Returns: Turnuva bilgisi ve maç listesi
    static func fetchTournamentWithMatches(tournamentId: String? = nil) async throws -> TournamentWithMatchesDTO {
        let params: [String: String]
        if let id = tournamentId {
            params = ["p_tournament_id": id]
        } else {
            params = [:]
        }
        
        let response: TournamentWithMatchesDTO = try await client
            .rpc("get_tournament_with_matches", params: params)
            .single()
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
