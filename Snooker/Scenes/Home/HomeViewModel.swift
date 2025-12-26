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
    func selectHomePlayer(at indexPath: IndexPath)
    func selectAwayPlayer(at indexPath: IndexPath)
}

enum HomeViewModelOutput: Sendable {
    case showLoading(Bool)
    case displayTournament(TournamentHeaderPresentation)
    case displaySections([MatchSection])
    case showError(String)
    case showEmptyState(Bool)
}

enum HomeRoute: Sendable {
    case matchDetail(matchId: String, homePlayerName: String, awayPlayerName: String)
    case playerDetail(playerId: String, playerName: String)
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
    private let tournamentId: String?
    private var tournament: TournamentWithMatchesDTO?
    private var sections: [MatchSection] = []
    
    init(service: HomeServiceProtocol, tournamentId: String? = nil) {
        self.service = service
        self.tournamentId = tournamentId
    }
    
    func loadData() {
        delegate?.handleOutput(.showLoading(true))
        
        Task {
            do {
                let tournament = try await service.fetchTournament(id: tournamentId)
                self.tournament = tournament
                
                delegate?.handleOutput(.showLoading(false))
                
                // Turnuva bilgilerini gönder
                let tournamentPresentation = TournamentHeaderPresentation(tournament: tournament)
                delegate?.handleOutput(.displayTournament(tournamentPresentation))
                
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
        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].matches.count else { return }
        
        let matchPresentation = sections[indexPath.section].matches[indexPath.row]
        let homePlayerFullName = "\(matchPresentation.homePlayerName) \(matchPresentation.homePlayerSurname)"
        let awayPlayerFullName = "\(matchPresentation.awayPlayerName) \(matchPresentation.awayPlayerSurname)"
        
        delegate?.navigate(to: .matchDetail(
            matchId: matchPresentation.matchId,
            homePlayerName: homePlayerFullName,
            awayPlayerName: awayPlayerFullName
        ))
    }
    
    func selectHomePlayer(at indexPath: IndexPath) {
        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].matches.count else { return }
        
        let matchPresentation = sections[indexPath.section].matches[indexPath.row]
        let playerFullName = "\(matchPresentation.homePlayerName) \(matchPresentation.homePlayerSurname)"
        
        delegate?.navigate(to: .playerDetail(
            playerId: matchPresentation.homePlayerId,
            playerName: playerFullName
        ))
    }
    
    func selectAwayPlayer(at indexPath: IndexPath) {
        guard indexPath.section < sections.count,
              indexPath.row < sections[indexPath.section].matches.count else { return }
        
        let matchPresentation = sections[indexPath.section].matches[indexPath.row]
        let playerFullName = "\(matchPresentation.awayPlayerName) \(matchPresentation.awayPlayerSurname)"
        
        delegate?.navigate(to: .playerDetail(
            playerId: matchPresentation.awayPlayerId,
            playerName: playerFullName
        ))
    }
    
    // MARK: - Private Methods
    
    private func createSections(from matches: [MatchDTO]) -> [MatchSection] {
        // API'den gelen sırayı koruyarak round'lara göre grupla
        // LinkedHashMap mantığı: ilk gelen round önce kalır
        var orderedRounds: [String] = []
        var groupedMatches: [String: [MatchDTO]] = [:]
        
        for match in matches {
            if groupedMatches[match.round] == nil {
                orderedRounds.append(match.round)
                groupedMatches[match.round] = []
            }
            groupedMatches[match.round]?.append(match)
        }
        
        // Section'ları API'den gelen sırada oluştur
        var sections: [MatchSection] = []
        
        for roundName in orderedRounds {
            guard let roundMatches = groupedMatches[roundName] else { continue }
            
            let roundType = RoundType.from(roundName)
            let matchPresentations = roundMatches.map { HomeCellPresentation(match: $0) }
            
            let section = MatchSection(
                roundName: roundName,
                roundType: roundType,
                matches: matchPresentations
            )
            
            sections.append(section)
        }
        
        return sections
    }
}
