//
//  SeasonListService.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import Foundation

protocol SeasonListServiceProtocol: AnyObject {
  func fetchSeason(completion: @escaping (Result<[DummyModel], Error>) -> Void)
}

final class SeasonListService: SeasonListServiceProtocol {
  func fetchSeason(completion: @escaping (Result<[DummyModel], any Error>) -> Void) {
//    <#code#>
  }
}
