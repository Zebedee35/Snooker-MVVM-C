//
//  HomeViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import UIKit

@MainActor
protocol HomeViewModelProtocol: AnyObject {
    var delegate: HomeViewModelDelegate? { get set }
    func loadData()
    func refreshData()
    func selectMatch(at indexPath: IndexPath)
}

enum HomeViewModelOutput: Sendable {
    case showLoading(Bool)
    case displaySections([MatchSection])
    case showError(String)
    case showEmptyState(Bool)
}

enum HomeRoute: Sendable {
    case matchDetail(MatchDTO)
}

@MainActor
protocol HomeViewModelDelegate: AnyObject {
    func handleOutput(_ output: HomeViewModelOutput)
    func navigate(to route: HomeRoute)
}

@MainActor
final class HomeViewModel: HomeViewModelProtocol {
    weak var delegate: HomeViewModelDelegate?
    
    private let service: HomeServiceProtocol
    private var tournament: TournamentWithMatchesDTO?
    private var sections: [MatchSection] = []
    
    init(service: HomeServiceProtocol) {
        self.service = service
    }
    
    func loadData() {
        delegate?.handleOutput(.showLoading(true))
        
        Task {
            do {
                let tournament = try await service.fetchActiveTournament()
                self.tournament = tournament
                
                delegate?.handleOutput(.showLoading(false))
                
                if tournament.matches.isEmpty {
                    delegate?.handleOutput(.showEmptyState(true))
                } else {
                    delegate?.handleOutput(.showEmptyState(false))
                    
                    let sections = createSections(from: tournament.matches)
                    self.sections = sections
                    
                    delegate?.handleOutput(.displaySections(sections))
                }
            } catch {
                delegate?.handleOutput(.showLoading(false))
                delegate?.handleOutput(.showError(error.localizedDescription))
                print("Error fetching tournament: \(error)")
            }
        }
    }
    
    func refreshData() {
        loadData()
    }
    
    func selectMatch(at indexPath: IndexPath) {
        guard let tournament = tournament,
              indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].matches.count else { return }
        
        let matchPresentation = sections[indexPath.section].matches[indexPath.row]
        
        // MatchDTO'yu bul
        if let match = tournament.matches.first(where: { $0.id == matchPresentation.matchId }) {
            delegate?.navigate(to: .matchDetail(match))
        }
    }
    
    // MARK: - Private Methods
    
    private func createSections(from matches: [MatchDTO]) -> [MatchSection] {
        // Round'lara göre grupla
        var groupedMatches: [String: [MatchDTO]] = [:]
        
        for match in matches {
            if groupedMatches[match.round] == nil {
                groupedMatches[match.round] = []
            }
            groupedMatches[match.round]?.append(match)
        }
        
        // Section'ları oluştur
        var sections: [MatchSection] = []
        
        for (roundName, roundMatches) in groupedMatches {
            let roundType = RoundType.from(roundName)
            
            // Maçları tarihe göre sırala
            let sortedMatches = roundMatches.sorted { match1, match2 in
                guard let date1 = match1.startDateTime,
                      let date2 = match2.startDateTime else {
                    return false
                }
                return date1 < date2
            }
            
            let matchPresentations = sortedMatches.map { HomeCellPresentation(match: $0) }
            
            let section = MatchSection(
                roundName: roundName,
                roundType: roundType,
                matches: matchPresentations
            )
            
            sections.append(section)
        }
        
        // Section'ları round önemine göre sırala (Final en üstte)
        sections.sort { $0.roundType.sortOrder < $1.roundType.sortOrder }
        
        return sections
    }
}
