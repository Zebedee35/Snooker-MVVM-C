//
//  AppAnnouncementDTO.swift
//  Snooker
//
//  Created by GitHub Copilot on 22.04.2026.
//

import Foundation

enum AnnouncementType: String, Decodable, Sendable {
    case error
    case info
    case warning
    case success

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        self = AnnouncementType(rawValue: rawValue) ?? .info
    }
}

enum AnnouncementDisplayMode: String, Decodable, Sendable {
    case oneTime = "one_time"
    case persistent

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        switch rawValue {
        case "one_time", "one-time", "single":
            self = .oneTime
        case "persistent", "continuous", "always":
            self = .persistent
        default:
            self = .persistent
        }
    }
}

enum AnnouncementPlacement: String, Decodable, Sendable {
    case top
    case bottom

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self))?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        switch rawValue {
        case "top":
            self = .top
        case "bottom":
            self = .bottom
        default:
            self = .bottom
        }
    }
}

struct AppAnnouncementDTO: Decodable, Identifiable, Sendable {
    let id: String
    let announcementKind: AnnouncementType
    let content: String
    let expiresAt: String?
    let displayMode: AnnouncementDisplayMode
    let placementZone: AnnouncementPlacement
    let displayRank: Int
    let isActive: Bool
    let createdAt: String?

    var sanitizedContent: String {
        content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isContentValid: Bool {
        let value = sanitizedContent
        return !value.isEmpty && value.count <= 500
    }

    var expiresDate: Date? {
        Self.parseDate(expiresAt)
    }

    var createdDate: Date? {
        Self.parseDate(createdAt)
    }

    func isExpired(at now: Date = Date()) -> Bool {
        guard let expiresDate else { return false }
        return expiresDate <= now
    }

    private static func parseDate(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }

        if let date = isoWithFractionalSeconds.date(from: value) {
            return date
        }

        return isoWithoutFractionalSeconds.date(from: value)
    }

    private static let isoWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let isoWithoutFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

extension AppAnnouncementDTO {
    static let sqlFields = """
        id,
        announcement_kind,
        content,
        expires_at,
        display_mode,
        placement_zone,
        display_rank,
        is_active,
        created_at
    """
}
