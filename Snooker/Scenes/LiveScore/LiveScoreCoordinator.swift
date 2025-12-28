//
//  LiveScoreCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

final class LiveScoreCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var mainViewController: LiveScoreViewController?
    
    init(navigationController: UINavigationController!) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewController = LiveScoreBuilder.make()
        viewController.coordinator = self
        mainViewController = viewController
        navigationController.setViewControllers([viewController], animated: true)
    }
    
    func handle(route: LiveScoreRoute) {
        switch route {
        case .matchDetail(let matchId, let homePlayerName, let awayPlayerName):
            // TODO: MatchDetail ekranı oluşturulduğunda implement edilecek
            print("[LiveScoreCoordinator] Navigate to match detail - ID: \(matchId) | \(homePlayerName) vs \(awayPlayerName)")
            
        case .playerDetail(let presentation):
            let playerDetailVC = PlayerDetailViewController(presentation: presentation)
            
            if let sheet = playerDetailVC.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
            }
            
            navigationController.present(playerDetailVC, animated: true)
        }
    }
}
