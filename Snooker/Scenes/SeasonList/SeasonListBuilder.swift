//
//  SeasonListBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

class SeasonListBuilder {
  static func make() -> SeasonListViewController {
    let viewController = SeasonListViewController()
    let viewModel = SeasonListViewModel(service: SeasonListService())
    viewController.viewModel = viewModel
    
    return viewController
  }
}
