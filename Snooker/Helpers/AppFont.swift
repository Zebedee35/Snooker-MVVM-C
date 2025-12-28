//
//  AppFont.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import UIKit

// MARK: - App Font

/// Uygulama genelinde kullanılan Geogrotesque font ailesi
enum AppFont {
    
    // MARK: - Font Names
    
    private enum FontName: String {
        case thin = "Geogrotesque-Thin"
        case ultraLight = "Geogrotesque-UltraLight"
        case light = "Geogrotesque-Light"
        case regular = "Geogrotesque-Regular"
        case medium = "Geogrotesque-Medium"
        case semiBold = "Geogrotesque-SemiBold"
        case bold = "Geogrotesque-Bold"
    }
    
    // MARK: - Font Methods
    
    static func thin(size: CGFloat) -> UIFont {
        UIFont(name: FontName.thin.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .thin)
    }
    
    static func ultraLight(size: CGFloat) -> UIFont {
        UIFont(name: FontName.ultraLight.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .ultraLight)
    }
    
    static func light(size: CGFloat) -> UIFont {
        UIFont(name: FontName.light.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .light)
    }
    
    static func regular(size: CGFloat) -> UIFont {
        UIFont(name: FontName.regular.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .regular)
    }
    
    static func medium(size: CGFloat) -> UIFont {
        UIFont(name: FontName.medium.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }
    
    static func semiBold(size: CGFloat) -> UIFont {
        UIFont(name: FontName.semiBold.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .semibold)
    }
    
    static func bold(size: CGFloat) -> UIFont {
        UIFont(name: FontName.bold.rawValue, size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }
    
    // MARK: - Debug Helper
    
    /// Tüm yüklü fontları konsola yazdırır (debug için)
    static func printAllFonts() {
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
    }
}
