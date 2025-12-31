//
//  HeadToHeadCoordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

protocol HeadToHeadCoordinatorProtocol: Coordinator {
    func start(with headerPresentation: HeadToHeadHeaderPresentation)
}

final class HeadToHeadCoordinator: HeadToHeadCoordinatorProtocol {
    
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        // Not used - use start(with:) instead
    }
    
    func start(with headerPresentation: HeadToHeadHeaderPresentation) {
        let viewController = HeadToHeadBuilder.build(headerPresentation: headerPresentation)
        
        // Modal presentation with sheet
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        navigationController.present(viewController, animated: true)
    }
}
