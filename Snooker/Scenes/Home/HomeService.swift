//
//  HomeService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import Foundation

protocol HomeServiceProtocol: Sendable {
    func fetchActiveTournament() async throws -> TournamentWithMatchesDTO
}

final class HomeService: HomeServiceProtocol {
    func fetchActiveTournament() async throws -> TournamentWithMatchesDTO {
        return try await SupabaseAPI.fetchTournamentWithMatches()
    }
}
