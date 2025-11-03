//
//  CountryModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 15.04.2025.
//

// Note: Bu model şu an kullanılmıyor.
// PlayerDTO içinde country string olarak tutuluyor.
// Eğer gelecekte ülke detayları gerekirse aktif edilebilir.

struct CountryDTO: Decodable, Identifiable {
  let id: Int
  let iso: String
  let name: String
  let short: String
  let flag: String
}
