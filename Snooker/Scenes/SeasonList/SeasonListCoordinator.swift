//
//  SeasonListCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

final class SeasonListCoordinator: Coordinator {
  weak var navigationController: UINavigationController!
  weak var mainViewContoller: SeasonListViewController?
  
  init (navigationController: UINavigationController!) {
    self.navigationController = navigationController
  }
  
  func start() {
    let viewController = SeasonListBuilder.make()
    viewController.coordinator = self
    mainViewContoller = viewController
    navigationController.setViewControllers([viewController], animated: true)
  }
}
