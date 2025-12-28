//
//  PlayerDetailService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import Foundation

// MARK: - Protocol

protocol PlayerDetailServiceProtocol: Sendable {
    func fetchLatestMatches(playerId: String) async throws -> [PlayerMatchDTO]
}

// MARK: - Implementation

final class PlayerDetailService: PlayerDetailServiceProtocol {
    func fetchLatestMatches(playerId: String) async throws -> [PlayerMatchDTO] {
        try await SupabaseAPI.fetchLatestMatches(playerId: playerId)
    }
}
