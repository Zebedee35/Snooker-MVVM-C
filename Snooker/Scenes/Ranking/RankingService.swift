//
//  RankingService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

protocol RankingServiceProtocol: Sendable {
    func fetchRankings() async throws -> [RankingDTO]
}

final class RankingService: RankingServiceProtocol {
    func fetchRankings() async throws -> [RankingDTO] {
        return try await SupabaseAPI.fetchRankings()
    }
}
