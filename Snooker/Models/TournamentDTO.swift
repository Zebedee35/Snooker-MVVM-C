//
//  TournamentDTO.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 8.10.2025.
//

struct TournamentDTO: Decodable, Identifiable {
  let id: String
  let season: Int
  let name: String
  let startDate: String
  let endDate: String
  let city: String?
  let country: String?
  let venue: String?
  let continent: String?
  
  enum CodingKeys: String, CodingKey {
    case id
    case season
    case name
    case startDate // = "start_date"
    case endDate // = "end_date"
    case city
    case country
    case venue
    case continent
  }
}


extension TournamentDTO {
  static let sqlFields = """
            id, season, name, start_date, end_date
          , city, country, venue, continent
        """
  
  static let preview: TournamentDTO = .init(
    id: "e001",
    season: 2025,
    name: "World Championship",
    startDate: "2025-04-15",
    endDate: "2025-05-01",
    city: "Sheffield",
    country: "England",
    venue: nil,
    continent: nil
  )
  
  static let previewList: [TournamentDTO] = [
    .init(
      id: "e001",
      season: 2025,
      name: "World Championship",
      startDate: "2025-04-15",
      endDate: "2025-05-01",
      city: "Sheffield",
      country: "England",
      venue: nil,
      continent: nil
    ),
    .init(
      id: "e002",
      season: 2025,
      name: "UK Championship",
      startDate: "2025-12-01",
      endDate: "2025-12-08",
      city: "York",
      country: "England",
      venue: nil,
      continent: nil
    ),
    .init(
      id: "e003",
      season: 2025,
      name: "Masters",
      startDate: "2025-01-10",
      endDate: "2025-01-17",
      city: "London",
      country: "England",
      venue: nil,
      continent: nil
    )
  ]
  
}
