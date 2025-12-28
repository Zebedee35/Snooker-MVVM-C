//
//  PlayerDetailPresentation.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import Foundation

// MARK: - Player Detail Presentation

struct PlayerDetailPresentation {
    let playerId: String
    let firstName: String
    let surname: String
    let photoUrl: String?
    let flagEmoji: String?
    let country: String?
    let rank: Int?
    let dob: String?
    let turnedPro: Int?
    
    // MARK: - Computed Properties
    
    var fullName: String {
        "\(firstName) \(surname)"
    }
    
    /// Formatted birth date (e.g., "5 December 1975")
    var formattedBirthDate: String? {
        guard let dob = dob else { return nil }
        
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dob) else { return nil }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "d MMMM yyyy"
        outputFormatter.locale = Locale(identifier: "en_US")
        
        return outputFormatter.string(from: date)
    }
    
    /// Calculate age from birth date
    var age: Int? {
        guard let dob = dob else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let birthDate = formatter.date(from: dob) else { return nil }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
    
    /// Years as professional
    var yearsAsPro: Int? {
        guard let turnedPro = turnedPro else { return nil }
        let currentYear = Calendar.current.component(.year, from: Date())
        return currentYear - turnedPro
    }
}
