//
//  HomeService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import Foundation

protocol HomeServiceProtocol: Sendable {
    func fetchTournament(id: String?) async throws -> TournamentWithMatchesDTO
}

final class HomeService: HomeServiceProtocol {
    func fetchTournament(id: String? = nil) async throws -> TournamentWithMatchesDTO {
        return try await SupabaseAPI.fetchTournamentWithMatches(tournamentId: id)
    }
}
