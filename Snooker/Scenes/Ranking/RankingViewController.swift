//
//  RankingViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

final class RankingViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(RankCell.self, forCellReuseIdentifier: RankCell.identifier)
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .none
        return tableView
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No rankings available"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    // MARK: - Properties
    
    var viewModel: RankingViewModelProtocol! {
        didSet {
            viewModel.delegate = self
        }
    }
    
    var cellPresentations: [RankCellPresentation] = []
    var coordinator: RankingCoordinator?
    
    // MARK: - Lifecycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Rankings"
        
        setupUI()
        setupConstraints()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        
        viewModel.loadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }
}

// MARK: - UITableViewDataSource

extension RankingViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellPresentations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: RankCell.identifier, for: indexPath) as? RankCell else {
            return UITableViewCell()
        }
        
        let presentation = cellPresentations[indexPath.row]
        cell.configure(with: presentation)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension RankingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectRanking(at: indexPath.row)
    }
}

// MARK: - RankingViewModelDelegate

extension RankingViewController: RankingViewModelDelegate {
    func handleOutput(_ output: RankingViewModelOutput) {
        switch output {
        case .showLoading(let isLoading):
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
                refreshControl.endRefreshing()
            }
            
        case .displayRankings(let presentations):
            cellPresentations = presentations
            tableView.reloadData()
            
        case .showError(let message):
            // TODO: Show error alert or banner
            print("Error: \(message)")
            
        case .showEmptyState(let isEmpty):
            emptyStateLabel.isHidden = !isEmpty
            tableView.isHidden = isEmpty
        }
    }
    
    func navigate(to route: RankingRoute) {
        coordinator?.handle(route: route)
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct RankingViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                let viewController = RankingViewController()
                let mockService = MockRankingService()
                let viewModel = RankingViewModel(service: mockService)
                viewController.viewModel = viewModel
                
                let navController = UINavigationController(rootViewController: viewController)
                return navController
            }
            .previewDisplayName("Rankings - Light")
            
            UIViewControllerPreview {
                let viewController = RankingViewController()
                let mockService = MockRankingService()
                let viewModel = RankingViewModel(service: mockService)
                viewController.viewModel = viewModel
                
                let navController = UINavigationController(rootViewController: viewController)
                return navController
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Rankings - Dark")
            
            UIViewControllerPreview {
                let viewController = RankingViewController()
                let mockService = MockRankingServiceEmpty()
                let viewModel = RankingViewModel(service: mockService)
                viewController.viewModel = viewModel
                
                let navController = UINavigationController(rootViewController: viewController)
                return navController
            }
            .previewDisplayName("Rankings - Empty State")
        }
    }
}

// MARK: - Mock Services for Preview

final class MockRankingService: RankingServiceProtocol {
    func fetchRankings() async throws -> [RankingDTO] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return RankingDTO.previewList
    }
}

final class MockRankingServiceEmpty: RankingServiceProtocol {
    func fetchRankings() async throws -> [RankingDTO] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
}

#endif
