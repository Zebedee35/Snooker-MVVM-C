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
        case .playerDetail(let ranking):
            // TODO: PlayerDetail ekranı oluşturulduğunda burası implement edilecek
            print("Navigate to player detail: \(ranking.player.fullName)")
            // let detailCoordinator = PlayerDetailCoordinator(navigationController: navigationController, player: ranking.player)
            // detailCoordinator.start()
        }
    }
}
