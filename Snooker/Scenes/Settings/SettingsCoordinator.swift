//
//  SettingsCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit
import StoreKit
import AuthenticationServices

final class SettingsCoordinator: Coordinator {
    weak var navigationController: UINavigationController!
    weak var mainViewController: SettingsViewController?
    var childCoordinators: [Coordinator] = []
    
    // App Store IDs
    private let filmBoxAppId     = "887580814"
    private let contactNameAppId = "911678698"
    private let snookerAppId    = "1459165666"
    
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

        case .announcementsHistory:
            showAnnouncementsHistory()

        case .signInWithApple:
            startSignInWithApple()

        case .signOut:
            confirmSignOut()

        case .deleteAccount:
            confirmDeleteAccount()
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

    private func showAnnouncementsHistory() {
        let viewController = AnnouncementsHistoryViewController()
        navigationController.pushViewController(viewController, animated: true)
    }

    // MARK: - Sign in with Apple

    private func startSignInWithApple() {
        let controller = AppleSignInController()
        let anchor = navigationController.view.window

        controller.start(anchor: anchor) { [weak self] result in
            Task { @MainActor in
                do {
                    try await AuthManager.shared.signInWithApple(
                        idToken: result.idToken,
                        nonce: result.rawNonce,
                        fullName: result.fullName,
                        email: result.email,
                        authorizationCode: result.authorizationCode
                    )
                } catch {
                    self?.presentError(message: "Sign in failed. Please try again.")
                }
            }
        } onFailure: { [weak self] error in
            // The user cancelling the sheet is not an error worth surfacing.
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue { return }
            DispatchQueue.main.async {
                self?.presentError(message: "Sign in failed. Please try again.")
            }
        }
    }

    private func confirmSignOut() {
        let alert = UIAlertController(
            title: "Sign Out",
            message: "Are you sure you want to sign out?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            Task { await AuthManager.shared.signOut() }
        })
        navigationController.present(alert, animated: true)
    }

    // MARK: - Delete Account

    private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Account",
            message: "This permanently deletes your account and all associated data. This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.performDeleteAccount()
        })
        navigationController.present(alert, animated: true)
    }

    private func performDeleteAccount() {
        let progress = UIAlertController(
            title: nil,
            message: "Deleting your account…",
            preferredStyle: .alert
        )
        navigationController.present(progress, animated: true)

        Task { @MainActor in
            do {
                try await AuthManager.shared.deleteAccount()
                progress.dismiss(animated: true)
            } catch {
                progress.dismiss(animated: true) { [weak self] in
                    self?.presentError(message: "Could not delete your account. Please try again.")
                }
            }
        }
    }

    private func presentError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        navigationController.present(alert, animated: true)
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
