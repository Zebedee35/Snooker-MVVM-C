//
//  PlayerDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 3.11.2025.
//

struct PlayerDTO: Decodable {
  let firstName: String
  let surname: String
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
    "\(firstName) \(surname)"
  }
  
  // Bayrak emoji döndürür (countryCode'dan)
  // Supabase formatı: "gb-wls", "gb-eng", "HK", "CN" vs.
  var flagEmoji: String? {
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
      country: "England",
      countryCode: "GB",
      dob: "1975-12-05",
      turnedPro: 1992,
      photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
      rank: 1
    ),
    .init(
      firstName: "Judd",
      surname: "Trump",
      country: "England",
      countryCode: "GB",
      dob: "1989-08-20",
      turnedPro: 2005,
      photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg",
      rank: 2
    ),
    .init(
      firstName: "Mark",
      surname: "Selby",
      country: "England",
      countryCode: "GB",
      dob: "1983-06-19",
      turnedPro: 1999,
      photoUrl: "https://35coders.com/common/snooker/img/mselby.jpg",
      rank: 3
    )
  ]
}
