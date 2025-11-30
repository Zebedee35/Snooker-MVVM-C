//
//  LiveScoreBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import Foundation

final class LiveScoreBuilder {
    static func make() -> LiveScoreViewController {
        let viewController = LiveScoreViewController()
        let service = LiveScoreService()
        let viewModel = LiveScoreViewModel(service: service)
        viewController.viewModel = viewModel
        
        return viewController
    }
}
