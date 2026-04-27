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
    
    // Dark Mode ayarını uygula
    applyInitialDarkMode()
  }
  
  func start() {
    let mainTabBarCoordinator = MainTabBarCoordinator(navigationController: navigationController)
    childCoordinators[.tabBar] = mainTabBarCoordinator
    mainTabBarCoordinator.start()

    AnnouncementManager.shared.start(in: window)
  }
  
  private func applyInitialDarkMode() {
    // Dark Mode ayarı hiç set edilmediyse, sistemin modunu kaydet
    if UserDefaults.standard.object(forKey: "dark_mode") == nil {
      let systemIsDark = UITraitCollection.current.userInterfaceStyle == .dark
      UserDefaults.standard.set(systemIsDark, forKey: "dark_mode")
      window.overrideUserInterfaceStyle = systemIsDark ? .dark : .light
    } else {
      let isDarkMode = UserDefaults.standard.bool(forKey: "dark_mode")
      window.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
    }
  }
}
