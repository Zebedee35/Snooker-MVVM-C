//
//  HomeBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import Foundation

final class HomeBuilder {
    static func make() -> HomeViewController {
        let viewController = HomeViewController()
        let service = HomeService()
        let viewModel = HomeViewModel(service: service)
        viewController.viewModel = viewModel
        
        return viewController
    }
}
