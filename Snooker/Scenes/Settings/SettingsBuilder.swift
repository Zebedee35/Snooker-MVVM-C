//
//  SettingsBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

enum SettingsBuilder {
    static func make(delegate: SettingsViewModelDelegate? = nil) -> SettingsViewController {
        let viewModel = SettingsViewModel()
        viewModel.delegate = delegate
        let viewController = SettingsViewController(viewModel: viewModel)
        return viewController
    }
}
