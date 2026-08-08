//
//  MainCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 5.10.2025.
//

import UIKit

final class MainTabBarCoordinator: Coordinator {
  
  enum AppTabChildCoordinators {
    case home
    case live
    case ranking
    case season
    case settings
  }
  
  var childCoordinators: [AppTabChildCoordinators: Coordinator] = [:]
  let navigationController: UINavigationController

  private var mainController: MainTabBarController?

  /// Tab to open on. Defaults to Home; set before `start()` when rebuilding
  /// after a language change so the user stays where they were.
  var initialTabIndex: Int = 2

  /// The tab currently on screen, so a rebuild can restore it.
  var selectedTabIndex: Int { mainController?.selectedIndex ?? initialTabIndex }

  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    
    let viewController = MainTabBarBuilder.make()
    viewController.coordinator = self
    mainController = viewController

    // Her tab için ayrı navigation controller oluşturalım
    //
    // Tab labels are deliberately shorter than the screen titles they lead to
    // ("Live" vs "Live Scores"), because the tab bar gives each one about ten
    // characters. That only holds as long as the root view controllers set
    // `navigationItem.title` rather than `title` — `title` writes through to
    // tabBarItem.title and silently replaces these labels once the view loads.
    let seasonNavController = UINavigationController()
    let seasonCoordinator = SeasonListCoordinator(navigationController: seasonNavController)
    seasonCoordinator.start()
    
    seasonNavController.tabBarItem = UITabBarItem(title: L10n.Tab.season, image: UIImage(systemName: "calendar"), tag: 0)

    // Live tab
    let liveNavController = UINavigationController()
    let liveCoordinator = LiveScoreCoordinator(navigationController: liveNavController)
    liveCoordinator.start()
    
    liveNavController.tabBarItem = UITabBarItem(title: L10n.Tab.live, image: UIImage(systemName: "dot.radiowaves.left.and.right"), tag: 2)
      
    // Home tab
    let homeNavController = UINavigationController()
    let homeCoordinator = HomeCoordinator(navigationController: homeNavController)
    homeCoordinator.start()
    
    homeNavController.tabBarItem = UITabBarItem(title: L10n.Tab.home, image: UIImage(systemName: "house"), tag: 1)
    
    // Ranking tab
    let rankingNavController = UINavigationController()
    let rankingCoordinator = RankingCoordinator(navigationController: rankingNavController)
    rankingCoordinator.start()
    
    rankingNavController.tabBarItem = UITabBarItem(title: L10n.Tab.ranking, image: UIImage(systemName: "chart.bar"), tag: 3)

    // Settings tab
    let settingsNavController = UINavigationController()
    let settingsCoordinator = SettingsCoordinator(navigationController: settingsNavController)
    settingsCoordinator.start()
    
    settingsNavController.tabBarItem = UITabBarItem(title: L10n.Tab.settings, image: UIImage(systemName: "gear"), tag: 4)
    
    mainController!.viewControllers = [seasonNavController, liveNavController, homeNavController, rankingNavController, settingsNavController]
    mainController!.selectedIndex = initialTabIndex
    
    navigationController.setViewControllers([viewController], animated: false)
    childCoordinators[.season] = seasonCoordinator
    childCoordinators[.live] = liveCoordinator
    childCoordinators[.home] = homeCoordinator
    childCoordinators[.ranking] = rankingCoordinator
    childCoordinators[.settings] = settingsCoordinator
  }
  
}
