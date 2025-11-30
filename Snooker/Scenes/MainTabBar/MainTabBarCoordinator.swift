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
  
  init(navigationController: UINavigationController) {
    self.navigationController = navigationController
  }
  
  func start() {
    
    let viewController = MainTabBarBuilder.make()
    viewController.coordinator = self
    mainController = viewController

    // Her tab için ayrı navigation controller oluşturalım
    let seasonNavController = UINavigationController()
    let seasonCoordinator = SeasonListCoordinator(navigationController: seasonNavController)
    seasonCoordinator.start()
    
    seasonNavController.tabBarItem = UITabBarItem(title: "Season", image: UIImage(systemName: "calendar"), tag: 0)

    // Live tab
    let liveNavController = UINavigationController()
    let liveCoordinator = LiveScoreCoordinator(navigationController: liveNavController)
    liveCoordinator.start()
    
    liveNavController.tabBarItem = UITabBarItem(title: "Live", image: UIImage(systemName: "dot.radiowaves.left.and.right"), tag: 2)
      

    let tab1 = UIViewController()
    tab1.view.backgroundColor = .systemRed
    tab1.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 1)
    
    // Ranking tab
    let rankingNavController = UINavigationController()
    let rankingCoordinator = RankingCoordinator(navigationController: rankingNavController)
    rankingCoordinator.start()
    
    rankingNavController.tabBarItem = UITabBarItem(title: "Ranking", image: UIImage(systemName: "chart.bar"), tag: 3)

    let tab5 = UIViewController()
    tab5.view.backgroundColor = .systemPurple
    tab5.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 4)
    
    mainController!.viewControllers = [seasonNavController, liveNavController, tab1, rankingNavController, tab5]
    mainController!.selectedIndex = 2  
    
    navigationController.setViewControllers([viewController], animated: false)
    childCoordinators[.season] = seasonCoordinator
    childCoordinators[.live] = liveCoordinator
    childCoordinators[.ranking] = rankingCoordinator
  }
  
}
