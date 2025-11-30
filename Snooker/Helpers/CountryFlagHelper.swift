//
//  CountryFlagHelper.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

/// Ülke kodlarından bayrak emoji'si üreten yardımcı sınıf
enum CountryFlagHelper {
    
    // UK alt bölge kodları için mapping (3 harfli ve 2 harfli alternatifler)
    private static let ukSubRegions: [String: String] = [
        // 3 harfli kodlar (RPC response'dan gelen format)
        "WLS": "🏴󠁧󠁢󠁷󠁬󠁳󠁿", // Wales
        "WAL": "🏴󠁧󠁢󠁷󠁬󠁳󠁿", // Wales alternatif
        "SCT": "🏴󠁧󠁢󠁳󠁣󠁴󠁿", // Scotland
        "ENG": "🏴󠁧󠁢󠁥󠁮󠁧󠁿", // England
        "NIR": "🇬🇧",          // Northern Ireland (UK bayrağı)
        // Çin (3 harfli)
        "CHN": "🇨🇳",
        // Avustralya (3 harfli)
        "AUS": "🇦🇺",
        // Belçika (3 harfli)
        "BEL": "🇧🇪",
    ]
    
    /// Ülke kodundan bayrak emoji döndürür
    /// - Parameter countryCode: ISO 2/3 harfli kod veya alt bölge kodu (örn: "gb-eng", "gb-wls", "CN", "BE", "SCT", "ENG")
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
                if let flag = ukSubRegions[subRegion] {
                    return flag
                }
                code = String(parts[0])
            }
        }
        
        // 3 harfli UK/diğer bölge kodları için kontrol et
        if let flag = ukSubRegions[code] {
            return flag
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
