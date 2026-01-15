//
//  PlayerDetailViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import Foundation

// MARK: - Protocol

@MainActor
protocol PlayerDetailViewModelProtocol: AnyObject {
    var delegate: PlayerDetailViewModelDelegate? { get set }
    var presentation: PlayerDetailPresentation { get }
    func loadRecentMatches()
}

// MARK: - Output

enum PlayerDetailViewModelOutput: Sendable {
    case showMatchesLoading(Bool)
    case displayMatches([PlayerMatchSection])
    case showMatchesError(String)
    case showMatchesEmpty
}

// MARK: - Delegate

@MainActor
protocol PlayerDetailViewModelDelegate: AnyObject {
    func handleOutput(_ output: PlayerDetailViewModelOutput)
}

// MARK: - Implementation

@MainActor
final class PlayerDetailViewModel: PlayerDetailViewModelProtocol {
    
    // MARK: - Properties
    
    weak var delegate: PlayerDetailViewModelDelegate?
    let presentation: PlayerDetailPresentation
    
    private let service: PlayerDetailServiceProtocol
    private var matchSections: [PlayerMatchSection] = []
    
    private var hideTBDMatches: Bool {
        UserDefaults.standard.bool(forKey: "hide_tbd_matches")
    }
    
    // MARK: - Initialization
    
    init(presentation: PlayerDetailPresentation, service: PlayerDetailServiceProtocol = PlayerDetailService()) {
        self.presentation = presentation
        self.service = service
        setupNotifications()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Private Setup
    
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
            self.loadRecentMatches()
        }
    }
    
    // MARK: - Public Methods
    
    func loadRecentMatches() {
        delegate?.handleOutput(.showMatchesLoading(true))
        
        Task {
            do {
                let matches = try await service.fetchLatestMatches(playerId: presentation.playerId)
                
                delegate?.handleOutput(.showMatchesLoading(false))
                
                if matches.isEmpty {
                    delegate?.handleOutput(.showMatchesEmpty)
                } else {
                    let sections = createSections(from: matches)
                    self.matchSections = sections
                    delegate?.handleOutput(.displayMatches(sections))
                }
            } catch {
                delegate?.handleOutput(.showMatchesLoading(false))
                delegate?.handleOutput(.showMatchesError(error.localizedDescription))
                print("[PlayerDetailViewModel] Error fetching matches: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func createSections(from matches: [PlayerMatchDTO]) -> [PlayerMatchSection] {
        // Apply TBD filter if enabled
        let filteredMatches = hideTBDMatches 
            ? matches.filter { !$0.hasBothPlayersTBD }
            : matches
        
        // Turnuva bazlı grupla (sırayı koru)
        var orderedTournaments: [String] = []
        var groupedMatches: [String: [PlayerMatchDTO]] = [:]
        
        for match in filteredMatches {
            let key = "\(match.tournamentId)"
            if groupedMatches[key] == nil {
                orderedTournaments.append(key)
                groupedMatches[key] = []
            }
            groupedMatches[key]?.append(match)
        }
        
        // Section'ları oluştur
        var sections: [PlayerMatchSection] = []
        
        for tournamentId in orderedTournaments {
            guard let tournamentMatches = groupedMatches[tournamentId],
                  let firstMatch = tournamentMatches.first else { continue }
            
            let presentations = tournamentMatches.map {
                PlayerMatchCellPresentation(match: $0, currentPlayerId: presentation.playerId)
            }
            
            let section = PlayerMatchSection(
                tournamentName: firstMatch.tournamentName,
                tournamentSeason: firstMatch.tournamentSeason,
                matches: presentations
            )
            
            sections.append(section)
        }
        
        return sections
    }
}
