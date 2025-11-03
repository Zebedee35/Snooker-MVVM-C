//
//  SeasonListService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListServiceProtocol: AnyObject {
  func fetchSeasons(completion: @escaping (Result<[TournamentDTO], Error>) -> Void)
}

final class SeasonListService: SeasonListServiceProtocol {
  func fetchSeasons(completion: @escaping (Result<[TournamentDTO], any Error>) -> Void) {
    Task {
      do {
        let seasons = try await SupabaseAPI.fetchSeasons()
        // Ana thread'de completion çağır
        DispatchQueue.main.async {
          completion(.success(seasons))
        }
      } catch {
        // Ana thread'de completion çağır
        DispatchQueue.main.async {
          completion(.failure(error))
        }
      }
    }
  }
}
