//
//  RankingViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

final class RankingViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(RankCell.self, forCellWithReuseIdentifier: RankCell.identifier)
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
        return collectionView
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
        label.font = AppFont.medium(size: 17)
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
    
    private var allCellPresentations: [RankCellPresentation] = []
    var cellPresentations: [RankCellPresentation] = []
    var coordinator: RankingCoordinator?
    
    private var hasLoadedData = false
    
    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search players..."
        return searchController
    }()
    
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
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.refreshControl = refreshControl
    }
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        // Setup search controller
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        
        // Lazy loading - sadece ilk görünümde yükle
        if !hasLoadedData {
            hasLoadedData = true
            viewModel.loadData()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(emptyStateLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension RankingViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellPresentations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RankCell.identifier, for: indexPath) as? RankCell else {
            return UICollectionViewCell()
        }
        
        let presentation = cellPresentations[indexPath.item]
        cell.configure(with: presentation)
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension RankingViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let presentation = cellPresentations[indexPath.item]
        viewModel.selectRanking(presentation: presentation)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension RankingViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 120)
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
            allCellPresentations = presentations
            filterContentForSearchText(searchController.searchBar.text)
            
        case .showError(let message):
            // TODO: Show error alert or banner
            print("Error: \(message)")
            
        case .showEmptyState(let isEmpty):
            emptyStateLabel.isHidden = !isEmpty
            collectionView.isHidden = isEmpty
        }
    }
    
    func navigate(to route: RankingRoute) {
        coordinator?.handle(route: route)
    }
}

// MARK: - UISearchResultsUpdating

extension RankingViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text)
    }
    
    private func filterContentForSearchText(_ searchText: String?) {
        guard let searchText = searchText, !searchText.isEmpty else {
            cellPresentations = allCellPresentations
            collectionView.reloadData()
            emptyStateLabel.isHidden = !allCellPresentations.isEmpty
            collectionView.isHidden = allCellPresentations.isEmpty
            return
        }
        
        let lowercasedSearchText = searchText.lowercased()
        cellPresentations = allCellPresentations.filter { presentation in
            let fullName = "\(presentation.playerName) \(presentation.playerSurname)".lowercased()
            return fullName.contains(lowercasedSearchText)
        }
        
        collectionView.reloadData()
        
        let isEmpty = cellPresentations.isEmpty
        emptyStateLabel.text = isEmpty ? "No players found" : "No rankings available"
        emptyStateLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
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
