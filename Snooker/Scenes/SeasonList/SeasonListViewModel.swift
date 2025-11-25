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
}

enum SeasonListViewModelOutput: Equatable, Sendable {
  case displaySeasons([SeasonListCellPresentation])
  case showLoading(Bool)
  
  static func == (lhs: SeasonListViewModelOutput, rhs: SeasonListViewModelOutput) -> Bool {
    switch (lhs, rhs) {
    case (.displaySeasons(let lhsSeasons), .displaySeasons(let rhsSeasons)):
      return lhsSeasons.count == rhsSeasons.count
    case (.showLoading(let lhsLoading), .showLoading(let rhsLoading)):
      return lhsLoading == rhsLoading
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
  
  init(service: SeasonListServiceProtocol) {
    self.service = service
  }
  
  func loadData() {
    delegate?.handleOutput(.showLoading(true))
    
    Task {
      do {
        let tournaments = try await service.fetchSeasons()
        self.tournaments = tournaments
        let cellPresentations = tournaments.map { SeasonListCellPresentation(tournament: $0) }
        delegate?.handleOutput(.showLoading(false))
        delegate?.handleOutput(.displaySeasons(cellPresentations))
      } catch {
        delegate?.handleOutput(.showLoading(false))
        print("Error fetching seasons: \(error)")
        // TODO: Error handling
      }
    }
  }
  
  func selectSeason(at index: Int) {
    guard index < tournaments.count else { return }
    let tournament = tournaments[index]
    delegate?.navigate(to: .seasonDetail(tournament))
  }
}

