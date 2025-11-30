//
//  LiveScoreViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

@MainActor
protocol LiveScoreViewModelProtocol: AnyObject {
    var delegate: LiveScoreViewModelDelegate? { get set }
    func loadData()
    func refreshData()
    func selectMatch(at index: Int)
}

enum LiveScoreViewModelOutput: Equatable, Sendable {
    case displayMatches([LiveScoreCellPresentation])
    case showLoading(Bool)
    case showError(String)
    case showEmptyState(Bool)
    
    static func == (lhs: LiveScoreViewModelOutput, rhs: LiveScoreViewModelOutput) -> Bool {
        switch (lhs, rhs) {
        case (.displayMatches(let lhsMatches), .displayMatches(let rhsMatches)):
            return lhsMatches.count == rhsMatches.count
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

enum LiveScoreRoute: Sendable {
    case matchDetail(MatchDTO)
}

@MainActor
protocol LiveScoreViewModelDelegate: AnyObject {
    func handleOutput(_ output: LiveScoreViewModelOutput)
    func navigate(to route: LiveScoreRoute)
}

@MainActor
final class LiveScoreViewModel: LiveScoreViewModelProtocol {
    weak var delegate: LiveScoreViewModelDelegate?
    
    private let service: LiveScoreServiceProtocol
    private var matches: [MatchDTO] = []
    
    init(service: LiveScoreServiceProtocol) {
        self.service = service
    }
    
    func loadData() {
        delegate?.handleOutput(.showLoading(true))
        
        Task {
            do {
                let matches = try await service.fetchLiveMatches()
                self.matches = matches
                
                delegate?.handleOutput(.showLoading(false))
                
                if matches.isEmpty {
                    delegate?.handleOutput(.showEmptyState(true))
                } else {
                    delegate?.handleOutput(.showEmptyState(false))
                    let cellPresentations = matches.map { LiveScoreCellPresentation(match: $0) }
                    delegate?.handleOutput(.displayMatches(cellPresentations))
                }
            } catch {
                delegate?.handleOutput(.showLoading(false))
                delegate?.handleOutput(.showError(error.localizedDescription))
                print("Error fetching live matches: \(error)")
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func selectMatch(at index: Int) {
        guard index < matches.count else { return }
        let match = matches[index]
        delegate?.navigate(to: .matchDetail(match))
    }
}
