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


    let tab1 = UIViewController()
    tab1.view.backgroundColor = .systemRed
    tab1.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 1)
    
    let tab2 = UIViewController()
    tab2.view.backgroundColor = .systemBlue
    tab2.tabBarItem = UITabBarItem(title: "Live", image: UIImage(systemName: "dot.radiowaves.left.and.right"), tag: 2)
    
    let tab3 = UIViewController()
    tab3.view.backgroundColor = .systemGreen
    tab3.tabBarItem = UITabBarItem(title: "Ranking", image: UIImage(systemName: "chart.bar"), tag: 3)

    let tab5 = UIViewController()
    tab5.view.backgroundColor = .systemPurple
    tab5.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 4)
    
    mainController!.viewControllers = [seasonNavController, tab1, tab2, tab3, tab5]
    
    navigationController.setViewControllers([viewController], animated: false)
    childCoordinators[.season] = seasonCoordinator
  }
  
}
