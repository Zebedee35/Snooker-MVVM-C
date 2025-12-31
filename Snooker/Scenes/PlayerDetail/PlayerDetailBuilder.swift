//
//  PlayerDetailBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

enum PlayerDetailBuilder {
    static func build(presentation: PlayerDetailPresentation, navigationDelegate: PlayerDetailViewControllerDelegate?) -> PlayerDetailViewController {
        let viewModel = PlayerDetailViewModel(presentation: presentation)
        let viewController = PlayerDetailViewController(viewModel: viewModel)
        viewController.navigationDelegate = navigationDelegate
        return viewController
    }
}
