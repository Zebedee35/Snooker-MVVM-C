//
//  HeadToHeadService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import Foundation

protocol HeadToHeadServiceProtocol {
    func fetchHeadToHead(player1Id: String, player2Id: String) async throws -> [HeadToHeadDTO]
}

final class HeadToHeadService: HeadToHeadServiceProtocol {
    func fetchHeadToHead(player1Id: String, player2Id: String) async throws -> [HeadToHeadDTO] {
        try await SupabaseAPI.fetchHeadToHead(player1Id: player1Id, player2Id: player2Id)
    }
}
