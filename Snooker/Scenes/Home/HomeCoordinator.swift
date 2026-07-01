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
    
    func showBracket(matches: [MatchDTO], title: String) {
        let viewController = BracketViewController(matches: matches, title: title)
        navigationController.pushViewController(viewController, animated: true)
    }

    func handle(route: HomeRoute) {
        switch route {
        case .matchDetail(let presentation):
            let detail = presentation.matchDetailPresentation()
            let viewController = MatchDetailBuilder.make(presentation: detail)
            viewController.onHeadToHeadTapped = { [weak self] in
                self?.presentHeadToHead(header: detail.headToHeadHeaderPresentation)
            }
            viewController.onHomePlayerTapped = { [weak self] in
                self?.openPlayerDetail(presentation.homePlayerDetailPresentation())
            }
            viewController.onAwayPlayerTapped = { [weak self] in
                self?.openPlayerDetail(presentation.awayPlayerDetailPresentation())
            }
            navigationController.pushViewController(viewController, animated: true)

        case .playerDetail(let presentation):
            openPlayerDetail(presentation)
        }
    }

    private func openPlayerDetail(_ presentation: PlayerDetailPresentation) {
        let playerDetailCoordinator = PlayerDetailCoordinator(navigationController: navigationController)
        playerDetailCoordinator.parentCoordinator = self
        childCoordinators.append(playerDetailCoordinator)
        playerDetailCoordinator.start(with: presentation)
    }

    /// Opens the existing Head-to-Head sheet for the two players.
    private func presentHeadToHead(header: HeadToHeadHeaderPresentation) {
        let pvpCoordinator = HeadToHeadCoordinator(navigationController: navigationController)
        pvpCoordinator.parentCoordinator = self
        childCoordinators.append(pvpCoordinator)
        pvpCoordinator.start(with: header)
    }
}
