//
//  SeasonListViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

@MainActor
protocol SeasonListViewModelProtocol: AnyObject {
  var delegate: SeasonListViewModelDelegate? { get set }
  func loadData()
  func selectSeason(at index: Int)
  func changeSeasonFilter(_ season: SeasonsDTO)
}

enum SeasonListViewModelOutput: Equatable, Sendable {
  case displaySeasons([SeasonListCellPresentation])
  case showLoading(Bool)
  case displaySeasonFilter([SeasonsDTO], selected: SeasonsDTO)

  static func == (lhs: SeasonListViewModelOutput, rhs: SeasonListViewModelOutput) -> Bool {
    switch (lhs, rhs) {
    case (.displaySeasons(let l), .displaySeasons(let r)):
      return l.count == r.count
    case (.showLoading(let l), .showLoading(let r)):
      return l == r
    case (.displaySeasonFilter(let lSeasons, let lSel), .displaySeasonFilter(let rSeasons, let rSel)):
      return lSeasons.count == rSeasons.count && lSel == rSel
    default:
      return false
    }
  }
}

enum SeasonListRoute: Sendable {
  case seasonDetail(TournamentDTO)
}

@MainActor
protocol SeasonListViewModelDelegate: AnyObject {
  func handleOutput(_ output: SeasonListViewModelOutput)
  func navigate(to route: SeasonListRoute)
}

@MainActor
final class SeasonListViewModel: SeasonListViewModelProtocol {
  weak var delegate: SeasonListViewModelDelegate?

  private let service: SeasonListServiceProtocol
  private var tournaments: [TournamentDTO] = []
  private var availableSeasons: [SeasonsDTO] = []
  private var selectedSeason: SeasonsDTO?

  init(service: SeasonListServiceProtocol) {
    self.service = service
  }

  func loadData() {
    delegate?.handleOutput(.showLoading(true))

    Task {
      do {
        let seasons = try await service.fetchAvailableSeasons()
        availableSeasons = seasons

        guard let season = seasons.first(where: { $0.current }) ?? seasons.first else {
          delegate?.handleOutput(.showLoading(false))
          return
        }

        selectedSeason = season
        delegate?.handleOutput(.displaySeasonFilter(seasons, selected: season))

        let fetched = try await service.fetchTournaments(for: season.id)
        tournaments = fetched
        delegate?.handleOutput(.showLoading(false))
        delegate?.handleOutput(.displaySeasons(fetched.map { SeasonListCellPresentation(tournament: $0) }))
      } catch {
        delegate?.handleOutput(.showLoading(false))
        print("Error fetching seasons: \(error)")
        // TODO: Error handling
      }
    }
  }

  func changeSeasonFilter(_ season: SeasonsDTO) {
    guard season != selectedSeason else { return }
    selectedSeason = season
    delegate?.handleOutput(.displaySeasonFilter(availableSeasons, selected: season))
    delegate?.handleOutput(.showLoading(true))

    Task {
      do {
        let fetched = try await service.fetchTournaments(for: season.id)
        tournaments = fetched
        delegate?.handleOutput(.showLoading(false))
        delegate?.handleOutput(.displaySeasons(fetched.map { SeasonListCellPresentation(tournament: $0) }))
      } catch {
        delegate?.handleOutput(.showLoading(false))
      }
    }
  }

  func selectSeason(at index: Int) {
    guard index < tournaments.count else { return }
    delegate?.navigate(to: .seasonDetail(tournaments[index]))
  }
}
