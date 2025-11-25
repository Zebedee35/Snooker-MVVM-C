//
//  RankingDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 15.04.2025.
//

struct RankingDTO: Decodable, Identifiable {
  let id: String
  let position: Int
  let prizeMoney: Double?
  let playerId: String
  let player: PlayerDTO  // PlayerDTO kullanıyoruz artık
  
  enum CodingKeys: String, CodingKey {
    case id
    case position
    case prizeMoney
    case playerId
    case player
  }
}

extension RankingDTO {
  static let sqlFields = """
            id,
            position,
            prize_money,
            player_id,
            player:player_id(first_name, surname, photo_url, country, country_code, turned_pro)
        """
  
  static let preview: RankingDTO = .init(
    id: "1",
    position: 1,
    prizeMoney: 800000,
    playerId: "p001",
    player: PlayerDTO(
      firstName: "Ronnie",
      surname: "O'Sullivan",
      country: "ENG",
      countryCode: "gb-eng",
      dob: "1975-12-05",
      turnedPro: 1992,
      photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
      rank: 1
    )
  )
  
  static let previewList: [RankingDTO] = [
    .init(
      id: "1",
      position: 1,
      prizeMoney: 800000,
      playerId: "p001",
      player: PlayerDTO(
        firstName: "Ronnie",
        surname: "O'Sullivan",
        country: "ENG",
        countryCode: "gb-eng",
        dob: "1975-12-05",
        turnedPro: 1992,
        photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
        rank: 1
      )
    ),
    .init(
      id: "2",
      position: 2,
      prizeMoney: 750000,
      playerId: "p002",
      player: PlayerDTO(
        firstName: "Judd",
        surname: "Trump",
        country: "ENG",
        countryCode: "gb-eng",
        dob: "1989-08-20",
        turnedPro: 2005,
        photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg",
        rank: 2
      )
    ),
    .init(
      id: "3",
      position: 3,
      prizeMoney: 700000,
      playerId: "p003",
      player: PlayerDTO(
        firstName: "Mark",
        surname: "Selby",
        country: "ENG",
        countryCode: "gb-eng",
        dob: "1983-06-19",
        turnedPro: 1999,
        photoUrl: "https://35coders.com/common/snooker/img/mselby.jpg",
        rank: 3
      )
    )
  ]
}
