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
        case .matchDetail(let match):
            // TODO: MatchDetail ekranı oluşturulduğunda implement edilecek
            print("Navigate to match detail: \(match.id)")
        }
    }
}
