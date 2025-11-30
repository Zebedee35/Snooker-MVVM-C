//
//  HomeCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import UIKit

final class HomeCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var mainViewController: HomeViewController?
    
    init(navigationController: UINavigationController!) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewController = HomeBuilder.make()
        viewController.coordinator = self
        mainViewController = viewController
        navigationController.setViewControllers([viewController], animated: true)
    }
    
    func handle(route: HomeRoute) {
        switch route {
        case .matchDetail(let matchId, let homePlayerName, let awayPlayerName):
            // TODO: MatchDetail ekranı oluşturulduğunda implement edilecek
            print("[HomeCoordinator] Navigate to match detail - ID: \(matchId) | \(homePlayerName) vs \(awayPlayerName)")
            
        case .playerDetail(let playerId, let playerName):
            // TODO: PlayerDetail ekranı oluşturulduğunda implement edilecek
            print("[HomeCoordinator] Navigate to player detail - ID: \(playerId) | \(playerName)")
        }
    }
}
