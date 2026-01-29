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
    func selectHomePlayer(at index: Int)
    func selectAwayPlayer(at index: Int)
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
    case matchDetail(presentation: LiveScoreCellPresentation)
    case playerDetail(presentation: PlayerDetailPresentation)
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
    private var cellPresentations: [LiveScoreCellPresentation] = []
    
    private var hideTBDMatches: Bool {
        UserDefaults.standard.bool(forKey: "hide_tbd_matches")
    }
    
    init(service: LiveScoreServiceProtocol) {
        self.service = service
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTBDSettingChanged),
            name: .hideTBDMatchesChanged,
            object: nil
        )
    }
    
    @objc private func handleTBDSettingChanged() {
        Task { @MainActor in
            self.loadData()
        }
    }
    
    func loadData() {
        delegate?.handleOutput(.showLoading(true))
        
        Task {
            do {
                let matches = try await service.fetchLiveMatches()
                
                delegate?.handleOutput(.showLoading(false))
                
                // Apply TBD filter if enabled
                let filteredMatches = hideTBDMatches 
                    ? matches.filter { !$0.hasBothPlayersTBD }
                    : matches
                
                if filteredMatches.isEmpty {
                    self.cellPresentations = []
                    delegate?.handleOutput(.displayMatches([]))
                    delegate?.handleOutput(.showEmptyState(true))
                } else {
                    delegate?.handleOutput(.showEmptyState(false))
                    let presentations = filteredMatches.map { LiveScoreCellPresentation(match: $0) }
                    self.cellPresentations = presentations
                    delegate?.handleOutput(.displayMatches(presentations))
                }
            } catch {
                delegate?.handleOutput(.showLoading(false))
                delegate?.handleOutput(.showEmptyState(true))
                delegate?.handleOutput(.showError(error.localizedDescription))
                print("Error fetching live matches: \(error)")
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func selectMatch(at index: Int) {
        guard index < cellPresentations.count else { return }
        let presentation = cellPresentations[index]
        
        delegate?.navigate(to: .matchDetail(presentation: presentation))
    }
    
    func selectHomePlayer(at index: Int) {
        guard index < cellPresentations.count else { return }
        let presentation = cellPresentations[index]
        let playerPresentation = presentation.homePlayerDetailPresentation()
        
        delegate?.navigate(to: .playerDetail(presentation: playerPresentation))
    }
    
    func selectAwayPlayer(at index: Int) {
        guard index < cellPresentations.count else { return }
        let presentation = cellPresentations[index]
        let playerPresentation = presentation.awayPlayerDetailPresentation()
        
        delegate?.navigate(to: .playerDetail(presentation: playerPresentation))
    }
}
