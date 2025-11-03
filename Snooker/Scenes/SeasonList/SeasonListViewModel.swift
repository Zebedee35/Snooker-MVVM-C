//
//  SeasonListViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListViewModelProtocol: AnyObject {
  var delegate: SeasonListViewModelDelegate? { get set }
  func loadData()
  func selectSeason(at index: Int)
}

enum SeasonListViewModelOutput: Equatable {
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

enum SeasonListRoute {
  case seasonDetail(TournamentDTO)
}

protocol SeasonListViewModelDelegate: AnyObject {
  func handleOutput(_ output: SeasonListViewModelOutput)
  func navigate(to route: SeasonListRoute)
}

final class SeasonListViewModel: SeasonListViewModelProtocol {
  weak var delegate: SeasonListViewModelDelegate?
  
  private let service: SeasonListServiceProtocol
  private var tournaments: [TournamentDTO] = []
  
  init(service: SeasonListServiceProtocol) {
    self.service = service
  }
  
  func loadData() {
    delegate?.handleOutput(.showLoading(true))
    service.fetchSeasons { [weak self] result in
      guard let self else { return }
      delegate?.handleOutput(.showLoading(false))
      switch result {
      case .success(let tournaments):
        self.tournaments = tournaments
        let cellPresentations = tournaments.map { SeasonListCellPresentation(tournament: $0) }
        delegate?.handleOutput(.displaySeasons(cellPresentations))
      case .failure(let error):
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

