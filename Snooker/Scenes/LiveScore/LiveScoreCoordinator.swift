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
        case .matchDetail(let match):
            // TODO: MatchDetail ekranı oluşturulduğunda burası implement edilecek
            print("Navigate to match detail: \(match.homePlayer.fullName) vs \(match.awayPlayer.fullName)")
            // let detailCoordinator = MatchDetailCoordinator(navigationController: navigationController, match: match)
            // detailCoordinator.start()
        }
    }
}
