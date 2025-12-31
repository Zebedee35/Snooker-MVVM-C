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
    var childCoordinators: [Coordinator] = []
    
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
        case .matchDetail(let presentation):
            let headerPresentation = HeadToHeadHeaderPresentation(
                player1Id: presentation.homePlayerId,
                player1Name: presentation.homePlayerName,
                player1Surname: presentation.homePlayerSurname,
                player1PhotoUrl: presentation.homePlayerPhotoUrl,
                player1Flag: presentation.homePlayerFlag,
                player2Id: presentation.awayPlayerId,
                player2Name: presentation.awayPlayerName,
                player2Surname: presentation.awayPlayerSurname,
                player2PhotoUrl: presentation.awayPlayerPhotoUrl,
                player2Flag: presentation.awayPlayerFlag
            )
            
            let pvpCoordinator = HeadToHeadCoordinator(navigationController: navigationController)
            pvpCoordinator.parentCoordinator = self
            childCoordinators.append(pvpCoordinator)
            pvpCoordinator.start(with: headerPresentation)
            
        case .playerDetail(let presentation):
            let playerDetailCoordinator = PlayerDetailCoordinator(navigationController: navigationController)
            playerDetailCoordinator.parentCoordinator = self
            childCoordinators.append(playerDetailCoordinator)
            playerDetailCoordinator.start(with: presentation)
        }
    }
}
