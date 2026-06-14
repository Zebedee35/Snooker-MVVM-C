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
    func isFollowing(at index: Int) -> Bool
    func toggleFollow(at index: Int)
}

enum LiveScoreViewModelOutput: Equatable, Sendable {
    case displayMatches([LiveScoreCellPresentation])
    case showLoading(Bool)
    case showError(String)
    case showEmptyState(Bool)
    case updateFollow(index: Int, isFollowing: Bool)

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
        case (.updateFollow(let li, let lf), .updateFollow(let ri, let rf)):
            return li == ri && lf == rf
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
                    syncLiveActivities(with: presentations)
                }
            } catch {
                self.cellPresentations = []
                delegate?.handleOutput(.showLoading(false))
                delegate?.handleOutput(.displayMatches([]))
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

    // MARK: - Live Activity Follow

    /// Whether a Live Activity is currently running for the match at `index`.
    func isFollowing(at index: Int) -> Bool {
        guard index < cellPresentations.count else { return false }
        guard #available(iOS 16.2, *) else { return false }
        return LiveActivityManager.shared.isActive(matchId: cellPresentations[index].matchId)
    }

    /// Start the Live Activity if not following, otherwise end it.
    func toggleFollow(at index: Int) {
        guard index < cellPresentations.count else { return }
        guard #available(iOS 16.2, *) else { return }

        let presentation = cellPresentations[index]
        let manager = LiveActivityManager.shared

        if manager.isActive(matchId: presentation.matchId) {
            manager.end(matchId: presentation.matchId)
        } else {
            manager.start(for: presentation, framesToWin: Self.framesToWin(for: presentation.round))
        }

        // Reflect the resulting state back to the cell.
        delegate?.handleOutput(.updateFollow(
            index: index,
            isFollowing: manager.isActive(matchId: presentation.matchId)
        ))
    }

    /// Keep any running Live Activities in sync with freshly fetched scores.
    ///
    /// The backend APNs push is the source of truth while the app is closed,
    /// but when the app is in the foreground (or recently backgrounded) a push
    /// may lag or be coalesced. So on every refresh we locally update the
    /// activity for matches we're following, and locally END it the moment a
    /// followed match comes back Completed/Finished — this is the foreground
    /// counterpart to the `event:"end"` push, so the activity doesn't linger
    /// if the push is missed.
    private func syncLiveActivities(with presentations: [LiveScoreCellPresentation]) {
        guard #available(iOS 16.2, *) else { return }
        let manager = LiveActivityManager.shared

        for p in presentations where manager.isActive(matchId: p.matchId) {
            let state = MatchLiveActivityAttributes.ContentState(
                homeScore: p.homePlayerScore,
                awayScore: p.awayPlayerScore,
                status: p.matchStatus,
                round: p.round,
                currentBreak: nil,
                atTable: nil
            )

            let status = p.matchStatus.lowercased()
            if status == "completed" || status == "finished" {
                manager.end(matchId: p.matchId, finalState: state)
            } else {
                manager.updateLocally(matchId: p.matchId, state: state)
            }
        }
    }

    /// Best-of frames needed to win, by round. Heuristic until the real
    /// best-of is exposed on MatchDTO / get_live_matches.
    private static func framesToWin(for round: String) -> Int {
        let r = round.lowercased()
        if r.contains("final"), !r.contains("semi"), !r.contains("quarter") { return 10 }
        if r.contains("semi") { return 6 }
        if r.contains("quarter") { return 5 }
        return 4
    }
}
