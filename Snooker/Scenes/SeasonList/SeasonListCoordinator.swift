//
//  SeasonListCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

final class SeasonListCoordinator: Coordinator {
  weak var navigationController: UINavigationController!
  weak var mainViewController: SeasonListViewController?
  
  init(navigationController: UINavigationController!) {
    self.navigationController = navigationController
  }
  
  func start() {
    let viewController = SeasonListBuilder.make()
    viewController.coordinator = self
    mainViewController = viewController
    navigationController.setViewControllers([viewController], animated: true)
  }
  
  func handle(route: SeasonListRoute) {
    switch route {
    case .seasonDetail(let tournament):
      let viewController = HomeBuilder.make(tournamentId: tournament.id)
      viewController.navigationItem.largeTitleDisplayMode = .never
      navigationController.pushViewController(viewController, animated: true)
    }
  }
}
