//
//  AppCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 5.10.2025.
//

import UIKit

final class AppCoordinator: Coordinator {
  
  enum AppChildCoordinators {
    case tabBar
  }
  
  let window: UIWindow
  private var childCoordinators: [AppChildCoordinators: Coordinator] = [:]
  let navigationController: UINavigationController
  
  init(window: UIWindow) {
    self.window = window
    self.navigationController = UINavigationController()
    navigationController.isNavigationBarHidden = true // tabbar kullanacagim icin gizledim.
    self.window.rootViewController = navigationController
    self.window.makeKeyAndVisible()
  }
  
  func start() {
    let mainTabBarCoordinator = MainTabBarCoordinator(navigationController: navigationController)
    childCoordinators[.tabBar] = mainTabBarCoordinator
    mainTabBarCoordinator.start()
  }
}
