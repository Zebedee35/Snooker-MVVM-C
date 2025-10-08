//
//  SeasonListBuilder.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

class SeasonListBuilder {
  static func make() -> SeasonListViewController {
    let viewController = SeasonListViewController()
    let service = SeasonListService()
    let viewModel = SeasonListViewModel(service: service)
    viewController.viewModel = viewModel
    
    return viewController
  }
}
