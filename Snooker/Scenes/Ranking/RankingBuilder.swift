//
//  RankingBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

final class RankingBuilder {
    static func make() -> RankingViewController {
        let viewController = RankingViewController()
        let service = RankingService()
        let viewModel = RankingViewModel(service: service)
        viewController.viewModel = viewModel
        
        return viewController
    }
}
