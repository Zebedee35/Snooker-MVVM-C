//
//  RankingCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

final class RankingCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var mainViewController: RankingViewController?
    var childCoordinators: [Coordinator] = []
    
    init(navigationController: UINavigationController!) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewController = RankingBuilder.make()
        viewController.coordinator = self
        mainViewController = viewController
        navigationController.setViewControllers([viewController], animated: true)
    }
    
    func handle(route: RankingRoute) {
        switch route {
        case .playerDetail(let presentation):
            let playerDetailCoordinator = PlayerDetailCoordinator(navigationController: navigationController)
            playerDetailCoordinator.parentCoordinator = self
            childCoordinators.append(playerDetailCoordinator)
            playerDetailCoordinator.start(with: presentation)
        }
    }
}
