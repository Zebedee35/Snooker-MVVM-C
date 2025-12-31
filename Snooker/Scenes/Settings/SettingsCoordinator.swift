//
//  SettingsCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit
import StoreKit

final class SettingsCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var mainViewController: SettingsViewController?
    var childCoordinators: [Coordinator] = []
    
    // App Store IDs
    private let filmBoxAppId = "1234567890"  // TODO: Replace with actual App ID
    private let contactNameAppId = "0987654321"  // TODO: Replace with actual App ID
    private let snookerAppId = "1111111111"  // TODO: Replace with actual App ID
    
    init(navigationController: UINavigationController!) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewController = SettingsBuilder.make(delegate: self)
        viewController.coordinator = self
        mainViewController = viewController
        
        navigationController.setViewControllers([viewController], animated: true)
    }
    
    func handle(route: SettingsRoute) {
        switch route {
        case .changeAppIcon:
            showAppIconPicker()
            
        case .filmBoxApp:
            openAppStore(appId: filmBoxAppId)
            
        case .contactNameApp:
            openAppStore(appId: contactNameAppId)
            
        case .rateUs:
            requestReview()
            
        case .shareApp:
            shareApp()
            
        case .giveFeedback:
            sendFeedbackEmail()
            
        case .website:
            openWebsite()
        }
    }
    
    // MARK: - Route Implementations
    
    private func showAppIconPicker() {
        // TODO: Implement app icon picker
        let alert = UIAlertController(
            title: "Change App Icon",
            message: "App icon selection coming soon!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
    }
    
    private func openAppStore(appId: String) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)") {
            UIApplication.shared.open(url)
        }
    }
    
    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    private func shareApp() {
        let appStoreURL = "https://apps.apple.com/app/id\(snookerAppId)"
        let message = "Check out Snooker Live Scores app! 🎱\n\(appStoreURL)"
        
        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )
        
        // iPad support
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = navigationController.view
            popover.sourceRect = CGRect(x: navigationController.view.bounds.midX, y: navigationController.view.bounds.midY, width: 0, height: 0)
        }
        
        navigationController.present(activityVC, animated: true)
    }
    
    private func sendFeedbackEmail() {
        let email = "tsusamcioglu@gmail.com"
        let subject = "Snooker App Feedback"
        
        if let url = URL(string: "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openWebsite() {
        if let url = URL(string: "https://35coders.com") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - SettingsViewModelDelegate

extension SettingsCoordinator: SettingsViewModelDelegate {
    func settingsDidUpdate() {
        mainViewController?.tableView?.reloadData()
    }
    
    func navigateTo(route: SettingsRoute) {
        handle(route: route)
    }
}

// MARK: - Private Extension

private extension UIViewController {
    var tableView: UITableView? {
        return view.subviews.compactMap { $0 as? UITableView }.first
    }
}
