//
//  SeasonListViewModel.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListViewModelProtocol: AnyObject {
  var delegate: SeasonListViewModelDelegate? { get set }
//  var someData: ModelData { get }
  func loadData()
}


enum SeasonListViewModelOutput {
  case showLoading(Bool)
}

protocol SeasonListViewModelDelegate: AnyObject {
  func handleOutput(_ output: SeasonListViewModelOutput)
//  func navigate(to route: ...)
}

final class SeasonListViewModel: SeasonListViewModelProtocol {
  var delegate: (any SeasonListViewModelDelegate)?
  var service: SeasonListServiceProtocol!
  
  init(service: SeasonListServiceProtocol) {
    self.service = service
  }
  
  func loadData() {
    delegate?.handleOutput(.showLoading(true))
    service.fetchSeason{[weak self] result in
      guard let self else {return}
      delegate?.handleOutput(.showLoading(false))
      switch result {
      case .success(let tours):
        print (tours)
      case .failure(let error):
        print (error)
      }
    }
  }
  
}
