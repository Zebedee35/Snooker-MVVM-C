//
//  SeasonListService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListServiceProtocol: Sendable {
  func fetchAvailableSeasons() async throws -> [SeasonsDTO]
  func fetchTournaments(for seasonId: Int) async throws -> [TournamentDTO]
}

final class SeasonListService: SeasonListServiceProtocol {
  func fetchAvailableSeasons() async throws -> [SeasonsDTO] {
    return try await SupabaseAPI.fetchSeasonsTableRows()
  }

  func fetchTournaments(for seasonId: Int) async throws -> [TournamentDTO] {
    return try await SupabaseAPI.fetchTournaments(seasonId: seasonId)
  }
}
