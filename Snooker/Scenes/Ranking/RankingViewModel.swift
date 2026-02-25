//
//  RankingViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

@MainActor
protocol RankingViewModelProtocol: AnyObject {
    var delegate: RankingViewModelDelegate? { get set }
    func loadData()
    func refreshData()
    func selectRanking(presentation: RankCellPresentation)
}

enum RankingViewModelOutput: Equatable, Sendable {
    case displayRankings([RankCellPresentation])
    case showLoading(Bool)
    case showError(String)
    case showEmptyState(Bool)
    
    static func == (lhs: RankingViewModelOutput, rhs: RankingViewModelOutput) -> Bool {
        switch (lhs, rhs) {
        case (.displayRankings(let lhsRankings), .displayRankings(let rhsRankings)):
            return lhsRankings.count == rhsRankings.count
        case (.showLoading(let lhsLoading), .showLoading(let rhsLoading)):
            return lhsLoading == rhsLoading
        case (.showError(let lhsError), .showError(let rhsError)):
            return lhsError == rhsError
        case (.showEmptyState(let lhsEmpty), .showEmptyState(let rhsEmpty)):
            return lhsEmpty == rhsEmpty
        default:
            return false
        }
    }
}

enum RankingRoute: Sendable {
    case playerDetail(presentation: PlayerDetailPresentation)
}

@MainActor
protocol RankingViewModelDelegate: AnyObject {
    func handleOutput(_ output: RankingViewModelOutput)
    func navigate(to route: RankingRoute)
}

@MainActor
final class RankingViewModel: RankingViewModelProtocol {
    weak var delegate: RankingViewModelDelegate?
    
    private let service: RankingServiceProtocol
    private var rankings: [RankingDTO] = []
    
    init(service: RankingServiceProtocol) {
        self.service = service
    }
    
    func loadData() {
        delegate?.handleOutput(.showLoading(true))
        
        Task {
            do {
                let rankings = try await service.fetchRankings()
                self.rankings = rankings
                
                delegate?.handleOutput(.showLoading(false))
                
                if rankings.isEmpty {
                    delegate?.handleOutput(.showEmptyState(true))
                } else {
                    delegate?.handleOutput(.showEmptyState(false))
                    let cellPresentations = rankings.map { RankCellPresentation(ranking: $0) }
                    delegate?.handleOutput(.displayRankings(cellPresentations))
                }
            } catch {
                delegate?.handleOutput(.showLoading(false))
                delegate?.handleOutput(.showError(error.localizedDescription))
                print("Error fetching rankings: \(error)")
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func selectRanking(presentation: RankCellPresentation) {
        let playerDetailPresentation = presentation.playerDetailPresentation()
        delegate?.navigate(to: .playerDetail(presentation: playerDetailPresentation))
    }
}
