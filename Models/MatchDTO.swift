//
//  MatchDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 22.05.2025.
//

struct LiveMatchFrameDTO: Decodable, Identifiable {
  let id: String
  let frameNumber: Int
  let homePlayerPoints: Int?
  let awayPlayerPoints: Int?
  let homePlayerFiftyPlusBreaks: Int?
  let awayPlayerFiftyPlusBreaks: Int?
  
  enum CodingKeys: String, CodingKey {
    case id
    case frameNumber
    case homePlayerPoints
    case awayPlayerPoints
    case homePlayerFiftyPlusBreaks
    case awayPlayerFiftyPlusBreaks
  }
}

// MARK: - MatchDTO

struct MatchDTO: Decodable, Identifiable {
  let id: String
  let round: String
  let status: String
  let startDateTime: String?
  let homePlayerId: String
  let awayPlayerId: String
  let homePlayerScore: Int?
  let awayPlayerScore: Int?
  let homePlayer: PlayerDTO  // PlayerDTO kullanıyoruz artık
  let awayPlayer: PlayerDTO  // PlayerDTO kullanıyoruz artık
  let frames: [LiveMatchFrameDTO]?

  enum CodingKeys: String, CodingKey {
    case id
    case round
    case status
    case startDateTime
    case homePlayerId
    case awayPlayerId
    case homePlayerScore
    case awayPlayerScore
    case homePlayer
    case awayPlayer
    case frames
  }
}

struct TournamentWithMatchesDTO: Decodable, Identifiable {
  let id: String
  let name: String
  let season: Int
  let startDate: String
  let endDate: String
  let city: String?
  let venue: String?
  let country: String?
  let matches: [MatchDTO]
  
  enum CodingKeys: String, CodingKey {
    case id
    case name
    case season
    case startDate
    case endDate 
    case city
    case venue
    case country
    case matches
  }
}

extension TournamentWithMatchesDTO {
  static let emptyData = TournamentWithMatchesDTO(
    id: "",
    name: "",
    season: 0,
    startDate: "",
    endDate: "",
    city: nil,
    venue: nil,
    country: nil,
    matches: []
  )

  static let preview: MatchDTO = .init(
      id: "fa23f5e4-1526-424d-9c6a-619c2b24d15b",
      round: "Final",
      status: "Completed",
      startDateTime: "2024-04-23T13:30:00+00:00",
      homePlayerId: "a8c0d3a6-706b-4bf0-8dce-9cde97fe88c4",
      awayPlayerId: "036bc430-6c51-4d63-a366-a6ca218f7f39",
      homePlayerScore: 18,
      awayPlayerScore: 14,
      homePlayer: PlayerDTO(
        firstName: "Jak",
        surname: "Jones",
        country: "WAL",
        dob: "1993",
        turnedPro: 2010,
        photoUrl: "https://35coders.com/common/snooker/img/mark-williams.jpg"
      ),
      awayPlayer: PlayerDTO(
        firstName: "Stuart",
        surname: "Bingham",
        country: "ENG",
        dob: "1976",
        turnedPro: 1995,
        photoUrl: "https://35coders.com/common/snooker/img/mselby.jpg"
      ),
      frames: nil
  )
  
  static let previewList: TournamentWithMatchesDTO = .init(
    id: "826cc9bf-2c3d-4171-a3eb-1c6588816e58",
    name: "Cazoo World Championship 2024",
    season: 2023,
    startDate: "2024-04-20",
    endDate: "2024-05-06",
    city: "Sheffield",
    venue: nil,
    country: "England",
    matches: [
      .init(
        id: "a4e81d0f-c20e-4f2a-88eb-84d3fbee53bc",
        round: "Semi Finals",
        status: "Completed",
        startDateTime: "2024-04-26T18:00:00+00:00",
        homePlayerId: "036bc430-6c51-4d63-a366-a6ca218f7f39",
        awayPlayerId: "ac932300-dacb-4e91-803b-99a03fa20853",
        homePlayerScore: 17,
        awayPlayerScore: 12,
        homePlayer: PlayerDTO(
          firstName: "Stuart",
          surname: "Bingham",
          country: "ENG",
          dob: "1976",
          turnedPro: 1995,
          photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg"
        ),
        awayPlayer: PlayerDTO(
          firstName: "Kyren",
          surname: "Wilson",
          country: "ENG",
          dob: "1991",
          turnedPro: 2010,
          photoUrl: "https://35coders.com/common/snooker/img/john-higgins.jpg"
        ),
        frames: nil
      ),
      .init(
        id: "407bf6e2-2b5f-4f6b-9638-4e34d46bf51a",
        round: "Round 1",
        status: "Completed",
        startDateTime: "2024-05-01T09:00:00+00:00",
        homePlayerId: "9b2532c1-a189-4573-8320-f254d2f9bfde",
        awayPlayerId: "c07238de-bca9-4067-9749-00841bd06d28",
        homePlayerScore: 13,
        awayPlayerScore: 8,
        homePlayer: PlayerDTO(
          firstName: "Stephen",
          surname: "Maguire",
          country: "SCT",
          dob: "1981",
          turnedPro: 1998,
          photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg"
        ),
        awayPlayer: PlayerDTO(
          firstName: "Pang",
          surname: "Junxu",
          country: "CHN",
          dob: "2000",
          turnedPro: 2020,
          photoUrl: "https://35coders.com/common/snooker/img/mselby.jpg"
        ),
        frames: nil
      ),
      .init(
        id: "407bf6e2-2b5f-4f6b-9638-2394839aa",
        round: "Round 1",
        status: "Completed",
        startDateTime: "2024-04-27T09:00:00+00:00",
        homePlayerId: "9b2532c1-a189-4573-8320-f254d2f9bfde",
        awayPlayerId: "c07238de-bca9-4067-9749-00841bd06d28",
        homePlayerScore: 6,
        awayPlayerScore: 13,
        homePlayer: PlayerDTO(
          firstName: "Luca",
          surname: "Brecel",
          country: "BLG",
          dob: "1995",
          turnedPro: 1995,
          photoUrl: "https://35coders.com/common/snooker/img/luca-brecel.jpg"
        ),
        awayPlayer: PlayerDTO(
          firstName: "Mark",
          surname: "Allen",
          country: "NRU",
          dob: "1986",
          turnedPro: 2005,
          photoUrl: "https://35coders.com/common/snooker/img/mark-allen.jpg"
        ),
        frames: nil
      ),
      .init(
        id: "fa23f5e4-1526-424d-9c6a-619c2b24d15b",
        round: "Final",
        status: "Completed",
        startDateTime: "2024-04-26T18:00:00+00:00",
        homePlayerId: "a8c0d3a6-706b-4bf0-8dce-9cde97fe88c4",
        awayPlayerId: "036bc430-6c51-4d63-a366-a6ca218f7f39",
        homePlayerScore: 18,
        awayPlayerScore: 14,
        homePlayer: PlayerDTO(
          firstName: "Jak",
          surname: "Jones",
          country: "WAL",
          dob: "1993",
          turnedPro: 2010,
          photoUrl: "https://35coders.com/common/snooker/img/judd-trump.jpg"
        ),
        awayPlayer: PlayerDTO(
          firstName: "Stuart",
          surname: "Bingham",
          country: "ENG",
          dob: "1976",
          turnedPro: 1995,
          photoUrl: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg"
        ),
        frames: nil
      )
    ]
  )
  
  static let livePreview: [MatchDTO] = [
    .init(
      id: "a58af8e3-e369-47f1-8b0b-8393e7a832c4",
      round: "Final",
      status: "Live",
      startDateTime: "2025-06-22T09:00:00+00:00",
      homePlayerId: "a85bdd17-6038-43c8-9cec-d492e4a8a2df",
      awayPlayerId: "96a6ed0f-faff-4dea-b155-04d7b5d52752",
      homePlayerScore: 4,
      awayPlayerScore: 4,
      homePlayer: PlayerDTO(
        firstName: "Jamie",
        surname: "Jones",
        country: "WAL",
        dob: "1988-02-14",
        turnedPro: 2006,
        photoUrl: nil
      ),
      awayPlayer: PlayerDTO(
        firstName: "Liu",
        surname: "Wenwei",
        country: "CHN",
        dob: "2003-12-08",
        turnedPro: nil,
        photoUrl: nil
      ),
      frames: [
        .init(
          id: "70909810-7516-4bfb-8bca-9bbdd168e370",
          frameNumber: 1,
          homePlayerPoints: 34,
          awayPlayerPoints: 63,
          homePlayerFiftyPlusBreaks: 0,
          awayPlayerFiftyPlusBreaks: 0
        ),
        .init(
          id: "4a83e89e-82e7-4fe8-b10f-b18f03759fc2",
          frameNumber: 2,
          homePlayerPoints: 62,
          awayPlayerPoints: 53,
          homePlayerFiftyPlusBreaks: 0,
          awayPlayerFiftyPlusBreaks: 53
        ),
        .init(
          id: "ddd87430-9df6-4434-ab8f-cf40e329a4ab",
          frameNumber: 3,
          homePlayerPoints: 98,
          awayPlayerPoints: 7,
          homePlayerFiftyPlusBreaks: 97,
          awayPlayerFiftyPlusBreaks: 0
        ),
        .init(
          id: "b3021cb2-5b1b-4be3-b5aa-a33f24f5d43a",
          frameNumber: 4,
          homePlayerPoints: 45,
          awayPlayerPoints: 66,
          homePlayerFiftyPlusBreaks: 0,
          awayPlayerFiftyPlusBreaks: 66
        ),
        .init(
          id: "c800df95-54bb-45cc-b698-559dcca3d367",
          frameNumber: 5,
          homePlayerPoints: 79,
          awayPlayerPoints: 26,
          homePlayerFiftyPlusBreaks: 58,
          awayPlayerFiftyPlusBreaks: 0
        )
      ]
    )
  ]

}
