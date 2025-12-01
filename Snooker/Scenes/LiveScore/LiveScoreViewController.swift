//
//  LiveScoreViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

final class LiveScoreViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(LiveScoreCell.self, forCellReuseIdentifier: LiveScoreCell.identifier)
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
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
        label.text = "No live matches at the moment"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 17, weight: .medium)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    private lazy var emptyStateContainerView: UIView = {
        let containerView = UIView()
        containerView.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: containerView.trailingAnchor, constant: -32)
        ])
        return containerView
    }()
    
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        return refreshControl
    }()
    
    // MARK: - Properties
    
    var viewModel: LiveScoreViewModelProtocol! {
        didSet {
            viewModel.delegate = self
        }
    }
    
    var cellPresentations: [LiveScoreCellPresentation] = []
    var coordinator: LiveScoreCoordinator?
    private var isEmptyState: Bool = false
    
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
        title = "Live Scores"
        
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
        
        // Empty state container'ı tableView'ın backgroundView'ı olarak ayarla
        tableView.backgroundView = emptyStateContainerView
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
    
    // MARK: - Actions
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }
}

// MARK: - UITableViewDataSource

extension LiveScoreViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellPresentations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LiveScoreCell.identifier, for: indexPath) as? LiveScoreCell else {
            return UITableViewCell()
        }
        
        let presentation = cellPresentations[indexPath.row]
        cell.configure(with: presentation)
        
        // Callback bindings
        cell.onHomePlayerTapped = { [weak self] in
            self?.viewModel.selectHomePlayer(at: indexPath.row)
        }
        cell.onAwayPlayerTapped = { [weak self] in
            self?.viewModel.selectAwayPlayer(at: indexPath.row)
        }
        cell.onScoreTapped = { [weak self] in
            self?.viewModel.selectMatch(at: indexPath.row)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LiveScoreViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectMatch(at: indexPath.row)
    }
}

// MARK: - LiveScoreViewModelDelegate

extension LiveScoreViewController: LiveScoreViewModelDelegate {
    func handleOutput(_ output: LiveScoreViewModelOutput) {
        switch output {
        case .showLoading(let isLoading):
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
                refreshControl.endRefreshing()
            }
            
        case .displayMatches(let presentations):
            cellPresentations = presentations
            tableView.reloadData()
            
        case .showError(let message):
            // TODO: Show error alert or banner
            print("Error: \(message)")
            
        case .showEmptyState(let isEmpty):
            isEmptyState = isEmpty
            emptyStateLabel.isHidden = !isEmpty
            tableView.reloadData()
        }
    }
    
    func navigate(to route: LiveScoreRoute) {
        coordinator?.handle(route: route)
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct LiveScoreViewController_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UIViewControllerPreview {
                let viewController = LiveScoreViewController()
                let mockService = MockLiveScoreService()
                let viewModel = LiveScoreViewModel(service: mockService)
                viewController.viewModel = viewModel
                
                let navController = UINavigationController(rootViewController: viewController)
                return navController
            }
            .previewDisplayName("Live Scores - Light")
            
            UIViewControllerPreview {
                let viewController = LiveScoreViewController()
                let mockService = MockLiveScoreService()
                let viewModel = LiveScoreViewModel(service: mockService)
                viewController.viewModel = viewModel
                
                let navController = UINavigationController(rootViewController: viewController)
                return navController
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Live Scores - Dark")
            
            UIViewControllerPreview {
                let viewController = LiveScoreViewController()
                let mockService = MockLiveScoreServiceEmpty()
                let viewModel = LiveScoreViewModel(service: mockService)
                viewController.viewModel = viewModel
                
                let navController = UINavigationController(rootViewController: viewController)
                return navController
            }
            .previewDisplayName("Live Scores - Empty State")
        }
    }
}

// MARK: - Mock Services for Preview

final class MockLiveScoreService: LiveScoreServiceProtocol {
    func fetchLiveMatches() async throws -> [MatchDTO] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return TournamentWithMatchesDTO.livePreview
    }
}

final class MockLiveScoreServiceEmpty: LiveScoreServiceProtocol {
    func fetchLiveMatches() async throws -> [MatchDTO] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }
}

#endif
