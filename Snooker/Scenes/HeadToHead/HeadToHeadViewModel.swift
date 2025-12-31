//
//  HeadToHeadViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import Foundation

// MARK: - Protocol

protocol HeadToHeadViewModelProtocol {
    var delegate: HeadToHeadViewModelDelegate? { get set }
    var headerPresentation: HeadToHeadHeaderPresentation { get }
    func load()
}

// MARK: - Delegate

protocol HeadToHeadViewModelDelegate: AnyObject {
    func handleOutput(_ output: HeadToHeadViewModelOutput)
}

// MARK: - Output

enum HeadToHeadViewModelOutput {
    case showLoading(Bool)
    case displayMatches([HeadToHeadMatchPresentation])
    case updateHeader(HeadToHeadHeaderPresentation)
    case showError(String)
    case showEmpty
}

// MARK: - ViewModel

final class HeadToHeadViewModel: HeadToHeadViewModelProtocol {
    
    weak var delegate: HeadToHeadViewModelDelegate?
    
    private(set) var headerPresentation: HeadToHeadHeaderPresentation
    private let service: HeadToHeadServiceProtocol
    
    init(headerPresentation: HeadToHeadHeaderPresentation, service: HeadToHeadServiceProtocol = HeadToHeadService()) {
        self.headerPresentation = headerPresentation
        self.service = service
    }
    
    func load() {
        Task { @MainActor in
            delegate?.handleOutput(.showLoading(true))
            
            do {
                let matches = try await service.fetchHeadToHead(
                    player1Id: headerPresentation.player1Id,
                    player2Id: headerPresentation.player2Id
                )
                
                delegate?.handleOutput(.showLoading(false))
                
                if matches.isEmpty {
                    delegate?.handleOutput(.showEmpty)
                } else {
                    let presentations = matches.map { dto in
                        HeadToHeadMatchPresentation(dto: dto, player1Id: headerPresentation.player1Id)
                    }
                    
                    // Calculate wins
                    var player1Wins = 0
                    var player2Wins = 0
                    
                    for presentation in presentations {
                        if presentation.didPlayer1Win {
                            player1Wins += 1
                        } else {
                            player2Wins += 1
                        }
                    }
                    
                    // Update header with win counts
                    headerPresentation.player1Wins = player1Wins
                    headerPresentation.player2Wins = player2Wins
                    
                    delegate?.handleOutput(.updateHeader(headerPresentation))
                    delegate?.handleOutput(.displayMatches(presentations))
                }
            } catch {
                delegate?.handleOutput(.showLoading(false))
                delegate?.handleOutput(.showError(error.localizedDescription))
            }
        }
    }
}
