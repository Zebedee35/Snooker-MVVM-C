//
//  PlayerNameHelper.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 21.02.2026.
//

import Foundation

/// Oyuncu isimlerini formatlamak için yardımcı sınıf
/// Çinli oyuncularda soyisim önce gelir: "Ding Junhui" -> "Ding J."
/// Diğer oyuncularda: "Judd Trump" -> "J. Trump"
enum PlayerNameHelper {
    
    /// Çin bayrağı emoji'si
    private static let chineseFlagEmoji = "🇨🇳"
    
    /// Çin ülke kodları
    private static let chineseCountryCodes: Set<String> = ["CN", "CHN", "CHINA"]
    
    /// İsmi kısaltır
    /// - Parameters:
    ///   - firstName: İsim
    ///   - surname: Soyisim
    ///   - flagEmoji: Bayrak emoji'si (ülkeyi belirlemek için)
    /// - Returns: Kısaltılmış isim
    static func shortenedName(firstName: String?, surname: String?, flagEmoji: String?) -> String {
        let first = firstName ?? ""
        let last = surname ?? ""
        
        // Eğer isim veya soyisim boşsa, mevcut olanı döndür
        guard !first.isEmpty, !last.isEmpty else {
            return first.isEmpty ? last : first
        }
        
        let isChinese = isChinesePlayer(flagEmoji: flagEmoji)
        
        if isChinese {
            // Çinli oyuncu: "Ding Junhui" -> "Ding J."
            // Soyisim tam, ismin ilk harfi
            let lastInitial = String(last.prefix(1))
            return "\(first) \(lastInitial)."
        } else {
            // Diğer oyuncular: "Judd Trump" -> "J. Trump"
            // İsmin ilk harfi, soyisim tam
            let firstInitial = String(first.prefix(1))
            return "\(firstInitial). \(last)"
        }
    }
    
    /// İsmi kısaltır (ülke kodu ile)
    /// - Parameters:
    ///   - firstName: İsim
    ///   - surname: Soyisim
    ///   - countryCode: Ülke kodu (CN, CHN, etc.)
    /// - Returns: Kısaltılmış isim
    static func shortenedName(firstName: String?, surname: String?, countryCode: String?) -> String {
        let flagEmoji = countryCode.flatMap { CountryFlagHelper.flagEmoji(for: $0) }
        return shortenedName(firstName: firstName, surname: surname, flagEmoji: flagEmoji)
    }
    
    /// Tam ismi döndürür (Çinli oyuncular için soyisim önce)
    /// - Parameters:
    ///   - firstName: İsim
    ///   - surname: Soyisim
    ///   - flagEmoji: Bayrak emoji'si
    /// - Returns: Tam isim
    static func fullName(firstName: String?, surname: String?, flagEmoji: String?) -> String {
        let first = firstName ?? ""
        let last = surname ?? ""
        
        guard !first.isEmpty, !last.isEmpty else {
            return first.isEmpty ? last : first
        }
        
        let isChinese = isChinesePlayer(flagEmoji: flagEmoji)
        
        if isChinese {
            // Çinli oyuncu: soyisim önce
            // return "\(last) \(first)"
            return "\(first) \(last)"
        } else {
            // Diğer oyuncular: isim önce
            return "\(first) \(last)"
        }
    }
    
    /// Oyuncunun Çinli olup olmadığını kontrol eder
    /// - Parameter flagEmoji: Bayrak emoji'si
    /// - Returns: Çinli ise true
    static func isChinesePlayer(flagEmoji: String?) -> Bool {
        guard let flag = flagEmoji else { return false }
        return flag == chineseFlagEmoji
    }
    
    /// Oyuncunun Çinli olup olmadığını kontrol eder (ülke kodu ile)
    /// - Parameter countryCode: Ülke kodu
    /// - Returns: Çinli ise true
    static func isChinesePlayer(countryCode: String?) -> Bool {
        guard let code = countryCode?.uppercased() else { return false }
        return chineseCountryCodes.contains(code)
    }
}
