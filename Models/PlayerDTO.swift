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
  let dob: String?
  let turnedPro: Int?
  let photoUrl: String?
  
  enum CodingKeys: String, CodingKey {
    case firstName
    case surname
    case country
    case dob
    case turnedPro
    case photoUrl
  }
  
  // Computed property for full name
  var fullName: String {
    "\(firstName) \(surname)"
  }
}

extension PlayerDTO {
  static let preview: PlayerDTO = .init(
    firstName: "Ronnie",
    surname: "O'Sullivan",
    country: "England",
    dob: "1975-12-05",
    turnedPro: 1992,
    photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg"
  )
  
  static let previewList: [PlayerDTO] = [
    .init(
      firstName: "Ronnie",
      surname: "O'Sullivan",
      country: "England",
      dob: "1975-12-05",
      turnedPro: 1992,
      photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg"
    ),
    .init(
      firstName: "Judd",
      surname: "Trump",
      country: "England",
      dob: "1989-08-20",
      turnedPro: 2005,
      photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg"
    ),
    .init(
      firstName: "Mark",
      surname: "Selby",
      country: "England",
      dob: "1983-06-19",
      turnedPro: 1999,
      photoUrl: "https://35coders.com/common/snooker/img/mselby.jpg"
    )
  ]
}
