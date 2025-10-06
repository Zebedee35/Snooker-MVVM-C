//
//  MainTabBarController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 5.10.2025.
//

import UIKit

final class MainTabBarController: UITabBarController {
  
  var coordinator: MainTabBarCoordinator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    setupTabBarAppearance()
  }
  
  private func setupTabBarAppearance() {
    tabBar.tintColor = .systemBlue
//    tabBar.backgroundColor = .systemBackground
//    tabBar.isTranslucent = false
  }
  
}
