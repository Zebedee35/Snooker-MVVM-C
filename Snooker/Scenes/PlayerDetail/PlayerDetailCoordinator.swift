//
//  PlayerDetailCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

protocol PlayerDetailCoordinatorProtocol: Coordinator {
    func start(with presentation: PlayerDetailPresentation)
}

final class PlayerDetailCoordinator: PlayerDetailCoordinatorProtocol {
    
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    
    private var presentedViewController: PlayerDetailViewController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Not used - use start(with:) instead
    }
    
    func start(with presentation: PlayerDetailPresentation) {
        let viewController = PlayerDetailBuilder.build(
            presentation: presentation,
            navigationDelegate: self
        )
        
        // Modal presentation with sheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        presentedViewController = viewController
        navigationController.present(viewController, animated: true)
    }
}

// MARK: - PlayerDetailViewControllerDelegate

extension PlayerDetailCoordinator: PlayerDetailViewControllerDelegate {
    func playerDetailViewController(_ viewController: PlayerDetailViewController, didRequestPvPWith presentation: HeadToHeadHeaderPresentation) {
        // Dismiss current modal and show PvP
        viewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            let pvpCoordinator = HeadToHeadCoordinator(navigationController: self.navigationController)
            pvpCoordinator.parentCoordinator = self
            self.childCoordinators.append(pvpCoordinator)
            pvpCoordinator.start(with: presentation)
        }
    }
}
