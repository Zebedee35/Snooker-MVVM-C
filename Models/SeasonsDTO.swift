//
//  SeasonsDTO.swift
//  Snooker
//
//  Created by GitHub Copilot on 14.05.2026.
//

import Foundation

struct SeasonsDTO: Decodable, Identifiable, Sendable {
    let id: Int
    let name: String
    let current: Bool
    let tournamentsFirst: String
    let tournamentsLast: String
    let createdAt: String?
    let updatedAt: String?
}

extension SeasonsDTO {
    static let sqlFields = """
        id,
        name,
        current,
        tournaments_first,
        tournaments_last,
        created_at,
        updated_at
    """
}
