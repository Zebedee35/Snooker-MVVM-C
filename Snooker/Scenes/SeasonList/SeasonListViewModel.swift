//
//  SeasonListViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListViewModelProtocol: AnyObject {
  var delegate: SeasonListViewModelDelegate? { get set }
  var service: SeasonListServiceProtocol! { get set }
//  var someData: ModelData { get }
  func loadData()
}


protocol SeasonListViewModelDelegate: AnyObject {
//  func handleOutput(_ output: ...)
//  func navigate(to route: ...)
}

final class SeasonListViewModel: SeasonListViewModelProtocol {
  var delegate: (any SeasonListViewModelDelegate)?
  var service: SeasonListServiceProtocol!
  
  init(service: SeasonListServiceProtocol) {
    self.service = service
  }
  
  func loadData() {
    // <#code#>
  }
  
  
}
