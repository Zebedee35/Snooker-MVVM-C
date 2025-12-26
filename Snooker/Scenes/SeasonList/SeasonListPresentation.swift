//
//  SeasonListPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 3.11.2025.
//

import Foundation

struct SeasonListCellPresentation: Sendable {
    let id: String
    let name: String
    let dateRange: String
    let location: String
    let startDateString: String
    let endDateString: String
    let isPast: Bool
    
    init(tournament: TournamentDTO) {
        self.id = tournament.id
        self.name = tournament.name
        self.startDateString = tournament.startDate
        self.endDateString = tournament.endDate
        self.dateRange = SeasonListCellPresentation.formatDateRange(start: tournament.startDate, end: tournament.endDate)
        
        var locationParts: [String] = []
        if let city = tournament.city {
            locationParts.append(city)
        }
        if let country = tournament.country {
            locationParts.append(country)
        }
        self.location = locationParts.isEmpty ? "Unknown" : locationParts.joined(separator: ", ")
        
        // Geçmiş mi kontrol et
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let endDate = formatter.date(from: tournament.endDate) {
            self.isPast = endDate < Date()
        } else {
            self.isPast = false
        }
    }
    
    private static func formatDateRange(start: String, end: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = formatter.date(from: start),
              let endDate = formatter.date(from: end) else {
            return "\(start) - \(end)"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM dd"
        
        let startString = displayFormatter.string(from: startDate)
        let endString = displayFormatter.string(from: endDate)
        
        return "\(startString) - \(endString)"
    }
}
