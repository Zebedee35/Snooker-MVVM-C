//
//  CountryFlagHelper.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

/// Ülke kodlarından bayrak emoji'si üreten yardımcı sınıf
enum CountryFlagHelper {
    
    /// Ülke kodundan bayrak emoji döndürür
    /// - Parameter countryCode: ISO 2 harfli kod veya alt bölge kodu (örn: "gb-eng", "gb-wls", "CN", "BE")
    /// - Returns: Bayrak emoji veya nil
    static func flagEmoji(for countryCode: String?) -> String? {
        guard var code = countryCode?.uppercased() else {
            return nil
        }
        
        // Alt bölge kodları (örn: GB-WLS, GB-SCT, GB-NIR, GB-ENG)
        if code.contains("-") {
            let parts = code.split(separator: "-")
            if parts.count == 2 {
                let subRegion = String(parts[1])
                switch subRegion {
                case "WLS": return "🏴󠁧󠁢󠁷󠁬󠁳󠁿" // Wales
                case "SCT": return "🏴󠁧󠁢󠁳󠁣󠁴󠁿" // Scotland
                case "ENG": return "🏴󠁧󠁢󠁥󠁮󠁧󠁿" // England
                case "NIR": return "🇬🇧" // Northern Ireland (UK bayrağı)
                default: code = String(parts[0])
                }
            }
        }
        
        // Standart 2 harfli ISO ülke kodu
        guard code.count == 2 else {
            return nil
        }
        
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in code.unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                emoji.append(String(scalarValue))
            }
        }
        return emoji.isEmpty ? nil : emoji
    }
}
