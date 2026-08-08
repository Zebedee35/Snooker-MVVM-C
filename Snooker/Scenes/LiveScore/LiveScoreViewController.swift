//
//  LiveScoreViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

final class LiveScoreViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(LiveScoreCell.self, forCellWithReuseIdentifier: LiveScoreCell.identifier)
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
        label.text = L10n.Live.empty
        label.textColor = .secondaryLabel
        label.font = AppFont.medium(size: 17)
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
    private var isViewVisible: Bool = false
    private var autoRefreshTimer: Timer?
    /// Canlı maç varken kullanılan yenileme aralığı. Skorları/frame'leri olabildiğince
    /// canlı tutmak için sık; throttle (VM) ile uyumlu.
    private let activeRefreshInterval: TimeInterval = 20
    /// Canlı maç yokken kullanılan boşta aralık — sadece yeni maç başladı mı diye
    /// seyrek yoklar, hızlı polling'i (ve egress'i) durdurur.
    private let idleRefreshInterval: TimeInterval = 300 // 5 minutes
    /// Timer'ın o an hangi aralıkla kurulduğu; gereksiz yeniden kurmayı önler.
    private var currentRefreshInterval: TimeInterval?
    
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
        // navigationItem.title, not title: setting `title` on a tab's root
        // view controller also writes through to its tabBarItem, which would
        // overwrite the short tab label the moment this view loads.
        navigationItem.title = L10n.Live.title
        
        setupUI()
        setupConstraints()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.refreshControl = refreshControl
        
        viewModel.loadData()
    }
    
    @objc private func handleRefresh() {
        viewModel.refreshData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        isViewVisible = true

        // Reload data when tab becomes visible (throttle'lı; sık tekrarları VM atar)
        viewModel.loadData()

        // Start auto-refresh timer
        updateAutoRefreshTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        isViewVisible = false

        // Stop auto-refresh timer when leaving the screen
        stopAutoRefreshTimer()
    }

    // MARK: - Auto Refresh

    /// Timer'ı mevcut duruma göre kurar: canlı maç varsa `activeRefreshInterval`,
    /// yoksa `idleRefreshInterval`. Aralık değişmediyse mevcut timer'a dokunmaz.
    private func updateAutoRefreshTimer() {
        guard isViewVisible else { return }

        let desiredInterval = isEmptyState ? idleRefreshInterval : activeRefreshInterval
        if currentRefreshInterval == desiredInterval, autoRefreshTimer != nil { return }

        currentRefreshInterval = desiredInterval
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = Timer.scheduledTimer(
            withTimeInterval: desiredInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.viewModel.loadData()
            }
        }
    }

    private func stopAutoRefreshTimer() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
        currentRefreshInterval = nil
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        
        // Empty state container'ı collectionView'ın backgroundView'ı olarak ayarla
        collectionView.backgroundView = emptyStateContainerView
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension LiveScoreViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellPresentations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveScoreCell.identifier, for: indexPath) as? LiveScoreCell else {
            return UICollectionViewCell()
        }
        
        let presentation = cellPresentations[indexPath.item]
        cell.configure(with: presentation)
        
        // Callback bindings
        cell.onHomePlayerTapped = { [weak self] in
            self?.viewModel.selectHomePlayer(at: indexPath.item)
        }
        cell.onAwayPlayerTapped = { [weak self] in
            self?.viewModel.selectAwayPlayer(at: indexPath.item)
        }
        cell.onScoreTapped = { [weak self] in
            self?.viewModel.selectMatch(at: indexPath.item)
        }

        // Follow (Live Activity) — only for ongoing matches on a supported OS.
        let status = presentation.matchStatus.lowercased()
        let isOngoing = (status == "live" || status == "break")
        let osSupported: Bool
        if #available(iOS 16.2, *) { osSupported = true } else { osSupported = false }
        cell.setFollowAvailable(isOngoing && osSupported)
        cell.setFollowing(viewModel.isFollowing(at: indexPath.item))
        cell.onFollowTapped = { [weak self] in
            self?.viewModel.toggleFollow(at: indexPath.item)
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension LiveScoreViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectMatch(at: indexPath.item)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension LiveScoreViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 176)
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
            collectionView.reloadData()
            
        case .showError(let message):
            // TODO: Show error alert or banner
            print("Error: \(message)")
            
        case .showEmptyState(let isEmpty):
            isEmptyState = isEmpty
            emptyStateLabel.isHidden = !isEmpty
            collectionView.reloadData()
            // Canlı maç varlığına göre polling hızını ayarla (egress).
            updateAutoRefreshTimer()

        case .updateFollow(let index, let isFollowing):
            let indexPath = IndexPath(item: index, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? LiveScoreCell {
                cell.setFollowing(isFollowing)
            }
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
