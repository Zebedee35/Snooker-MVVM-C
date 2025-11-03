//
//  SeasonListViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

final class SeasonListViewController: UIViewController {
  
  private let tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(SeasonListCell.self, forCellReuseIdentifier: SeasonListCell.identifier)
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 80
    return tableView
  }()
  
  private let activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = true
    return indicator
  }()

  var viewModel: SeasonListViewModelProtocol! {
    didSet {
       viewModel.delegate = self
    }
  }
  
  var cellPresentations: [SeasonListCellPresentation] = []
  var coordinator: SeasonListCoordinator?

  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    title = "Seasons"
    
    setupUI()
    setupConstraints()
    
    tableView.delegate = self
    tableView.dataSource = self
    
    viewModel.loadData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.prefersLargeTitles = true
  }
  
  private func setupUI() {
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
  }
  
  private func setupConstraints() {
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }
}

// MARK: - UITableViewDataSource
extension SeasonListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cellPresentations.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: SeasonListCell.identifier, for: indexPath) as? SeasonListCell else {
      return UITableViewCell()
    }
    
    let presentation = cellPresentations[indexPath.row]
    cell.configure(with: presentation)
    return cell
  }
}

// MARK: - UITableViewDelegate
extension SeasonListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    viewModel.selectSeason(at: indexPath.row)
  }
}

// MARK: - SeasonListViewModelDelegate
extension SeasonListViewController: SeasonListViewModelDelegate {
  func handleOutput(_ output: SeasonListViewModelOutput) {
    switch output {
    case .showLoading(let isLoading):
      if isLoading {
        activityIndicator.startAnimating()
      } else {
        activityIndicator.stopAnimating()
      }
    case .displaySeasons(let presentations):
      cellPresentations = presentations
      tableView.reloadData()
    }
  }
  
  func navigate(to route: SeasonListRoute) {
    coordinator?.handle(route: route)
  }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct SeasonListViewController_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Preview with mock data
      UIViewControllerPreview {
        let viewController = SeasonListViewController()
        let mockService = MockSeasonListService()
        let viewModel = SeasonListViewModel(service: mockService)
        viewController.viewModel = viewModel
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
      }
      .previewDisplayName("Season List - Light")
      
      UIViewControllerPreview {
        let viewController = SeasonListViewController()
        let mockService = MockSeasonListService()
        let viewModel = SeasonListViewModel(service: mockService)
        viewController.viewModel = viewModel
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
      }
      .preferredColorScheme(.dark)
      .previewDisplayName("Season List - Dark")
    }
  }
}

// MARK: - Preview Helpers

@available(iOS 13.0, *)
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
  let viewController: ViewController
  
  init(_ builder: @escaping () -> ViewController) {
    viewController = builder()
  }
  
  func makeUIViewController(context: Context) -> ViewController {
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

// MARK: - Mock Service for Preview

final class MockSeasonListService: SeasonListServiceProtocol {
  func fetchSeasons(completion: @escaping (Result<[TournamentDTO], Error>) -> Void) {
    // Simulate network delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      completion(.success(TournamentDTO.previewList))
    }
  }
}

#endif
