//
//  SceneDelegate.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 5.10.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?
  
  var appCoordinator: AppCoordinator?


  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
    guard let windowScene = (scene as? UIWindowScene) else { return }
    
    // Configure global navigation bar appearance with custom font
    configureNavigationBarAppearance()
    
    let window = UIWindow(windowScene: windowScene)
    
    // Apply saved Dark Mode preference
    applyDarkModePreference(to: window)
    
    appCoordinator = AppCoordinator(window: window)
    appCoordinator?.start()
  }
  
  private func applyDarkModePreference(to window: UIWindow) {
    let isDarkMode = UserDefaults.standard.bool(forKey: "dark_mode")
    window.overrideUserInterfaceStyle = isDarkMode ? .dark : .unspecified
  }
  
  private func configureNavigationBarAppearance() {
    // Standard appearance (scrolled state)
    let standardAppearance = UINavigationBarAppearance()
    standardAppearance.configureWithDefaultBackground()
    standardAppearance.backgroundColor = .systemBackground
    
    // Large title font
    standardAppearance.largeTitleTextAttributes = [
      .font: AppFont.bold(size: 34),
      .foregroundColor: UIColor.label
    ]
    
    // Standard title font
    standardAppearance.titleTextAttributes = [
      .font: AppFont.semiBold(size: 17),
      .foregroundColor: UIColor.label
    ]
    
    // Scroll edge appearance (top of scroll - large title visible)
    let scrollEdgeAppearance = UINavigationBarAppearance()
    scrollEdgeAppearance.configureWithTransparentBackground()
    
    scrollEdgeAppearance.largeTitleTextAttributes = [
      .font: AppFont.bold(size: 34),
      .foregroundColor: UIColor.label
    ]
    
    scrollEdgeAppearance.titleTextAttributes = [
      .font: AppFont.semiBold(size: 17),
      .foregroundColor: UIColor.label
    ]
    
    // Apply to all navigation bars
    UINavigationBar.appearance().standardAppearance = standardAppearance
    UINavigationBar.appearance().scrollEdgeAppearance = scrollEdgeAppearance
    UINavigationBar.appearance().compactAppearance = standardAppearance
    
    // Configure TabBar appearance
    let tabBarAppearance = UITabBarAppearance()
    tabBarAppearance.configureWithDefaultBackground()
    
    let tabBarItemAppearance = UITabBarItemAppearance()
    tabBarItemAppearance.normal.titleTextAttributes = [
      .font: AppFont.medium(size: 10)
    ]
    tabBarItemAppearance.selected.titleTextAttributes = [
      .font: AppFont.semiBold(size: 10)
    ]
    
    tabBarAppearance.stackedLayoutAppearance = tabBarItemAppearance
    tabBarAppearance.inlineLayoutAppearance = tabBarItemAppearance
    tabBarAppearance.compactInlineLayoutAppearance = tabBarItemAppearance
    
    UITabBar.appearance().standardAppearance = tabBarAppearance
    UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
  }


}

