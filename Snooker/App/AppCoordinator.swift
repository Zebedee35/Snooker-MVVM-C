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

    // Screens read their strings once, when they are built, so a language
    // change is handled by rebuilding the UI from the root rather than by
    // having every view controller observe and re-apply its own labels.
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleLanguageChanged),
      name: .appLanguageChanged,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func start() {
    startTabBar()
    AnnouncementManager.shared.start(in: window)
  }

  private func startTabBar(selectedTabIndex: Int = 2) {
    let mainTabBarCoordinator = MainTabBarCoordinator(navigationController: navigationController)
    mainTabBarCoordinator.initialTabIndex = selectedTabIndex
    childCoordinators[.tabBar] = mainTabBarCoordinator
    mainTabBarCoordinator.start()
  }

  /// Rebuilds the tab bar in the new language, landing the user back on the
  /// tab they were using. Any screen they had pushed is lost — an acceptable
  /// trade for not threading a language observer through every controller,
  /// since the change is always made from Settings.
  @objc private func handleLanguageChanged() {
    let previousTab = (childCoordinators[.tabBar] as? MainTabBarCoordinator)?.selectedTabIndex ?? 2

    UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve) { [weak self] in
      self?.startTabBar(selectedTabIndex: previousTab)
    }
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
