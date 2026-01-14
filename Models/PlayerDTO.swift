//
//  PlayerDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 3.11.2025.
//

struct PlayerDTO: Decodable {
  let firstName: String?
  let surname: String?
  let country: String?
  let countryCode: String?  // ISO 3166-1 alpha-2 (örn: "GB", "TR", "CN")
  let dob: String?
  let turnedPro: Int?
  let photoUrl: String?
  let rank: Int?  // Dünya sıralaması
  
  enum CodingKeys: String, CodingKey {
    case firstName
    case surname
    case country
    case countryCode
    case dob
    case turnedPro
    case photoUrl
    case rank
  }
  
  // Computed property for full name
  var fullName: String {
    "\(firstName ?? "TBD") \(surname ?? "")"
  }
  
  // Bayrak emoji döndürür (önce countryCode, yoksa country'ye bakar)
  // CountryFlagHelper kullanır
  var flagEmoji: String? {
    // Önce countryCode'a bak (gb-eng, gb-wls gibi)
    if let emoji = CountryFlagHelper.flagEmoji(for: countryCode) {
      return emoji
    }
    // countryCode yoksa country'ye bak (SCT, ENG, WAL gibi)
    return CountryFlagHelper.flagEmoji(for: country)
  }
}

extension PlayerDTO {
  static let preview: PlayerDTO = .init(
    firstName: "Ronnie",
    surname: "O'Sullivan",
    country: "ENG",
    countryCode: "gb-eng",
    dob: "1975-12-05",
    turnedPro: 1992,
    photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
    rank: 1
  )
  
  static let previewList: [PlayerDTO] = [
    .init(
      firstName: "Ronnie",
      surname: "O'Sullivan",
      country: "ENG",
      countryCode: "gb-eng",
      dob: "1975-12-05",
      turnedPro: 1992,
      photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
      rank: 1
    ),
    .init(
      firstName: "Judd",
      surname: "Trump",
      country: "ENG",
      countryCode: "gb-eng",
      dob: "1989-08-20",
      turnedPro: 2005,
      photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg",
      rank: 2
    ),
    .init(
      firstName: "Mark",
      surname: "Selby",
      country: "ENG",
      countryCode: "gb-eng",
      dob: "1983-06-19",
      turnedPro: 1999,
      photoUrl: "https://35coders.com/common/snooker/img/mselby.jpg",
      rank: 3
    )
  ]
}
