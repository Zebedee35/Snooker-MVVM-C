//
//  SeasonListService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListServiceProtocol: Sendable {
  func fetchSeasons() async throws -> [TournamentDTO]
}

final class SeasonListService: SeasonListServiceProtocol {
  func fetchSeasons() async throws -> [TournamentDTO] {
    return try await SupabaseAPI.fetchSeasons()
  }
}
