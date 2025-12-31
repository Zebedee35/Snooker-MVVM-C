//
//  Coordinator.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 5.10.2025.
//

import UIKit

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }
    var parentCoordinator: Coordinator? { get set }
    
    func start()
}

extension Coordinator {
    /// Default implementation - coordinators without parent
    var parentCoordinator: Coordinator? {
        get { nil }
        set { }
    }
    
    /// Default implementation - coordinators without children
    var childCoordinators: [Coordinator] {
        get { [] }
        set { }
    }
}
