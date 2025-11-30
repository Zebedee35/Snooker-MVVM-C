//
//  LiveScoreService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

protocol LiveScoreServiceProtocol: Sendable {
    func fetchLiveMatches() async throws -> [MatchDTO]
}

final class LiveScoreService: LiveScoreServiceProtocol {
    func fetchLiveMatches() async throws -> [MatchDTO] {
        return try await SupabaseAPI.fetchLiveMatches()
    }
}
