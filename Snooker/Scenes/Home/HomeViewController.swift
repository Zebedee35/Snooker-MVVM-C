//
//  HomeViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import UIKit

final class HomeViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.headerReferenceSize = CGSize(width: 0, height: 50)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(LiveScoreCell.self, forCellWithReuseIdentifier: LiveScoreCell.identifier)
        collectionView.register(ScoreCell.self, forCellWithReuseIdentifier: ScoreCell.identifier)
        collectionView.register(RoundHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: RoundHeaderView.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.alwaysBounceVertical = true
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
        label.text = "No active tournament"
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
    
    var viewModel: HomeViewModelProtocol! {
        didSet {
            viewModel.delegate = self
        }
    }
    
    var sections: [MatchSection] = []
    var coordinator: HomeCoordinator?
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
        title = "Home"
        
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
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}

// MARK: - UICollectionViewDataSource

extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].matches.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let matchPresentation = sections[indexPath.section].matches[indexPath.item]
        
        // Final ve Semi Final için büyük cell kullan
        if matchPresentation.usesBigCell {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveScoreCell.identifier, for: indexPath) as? LiveScoreCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: matchPresentation.toLiveScoreCellPresentation)
            
            // Live maç ise animasyon başlat
            if matchPresentation.isLive {
                cell.startLiveAnimation()
            } else {
                cell.stopLiveAnimation()
            }
            
            // Callback bindings
            cell.onHomePlayerTapped = { [weak self] in
                self?.viewModel.selectHomePlayer(at: indexPath)
            }
            cell.onAwayPlayerTapped = { [weak self] in
                self?.viewModel.selectAwayPlayer(at: indexPath)
            }
            cell.onScoreTapped = { [weak self] in
                self?.viewModel.selectMatch(at: indexPath)
            }
            
            return cell
        } else {
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScoreCell.identifier, for: indexPath) as? ScoreCell else {
                return UICollectionViewCell()
            }
            cell.configure(with: matchPresentation.toLiveScoreCellPresentation)
            
            // Callback bindings
            cell.onHomePlayerTapped = { [weak self] in
                self?.viewModel.selectHomePlayer(at: indexPath)
            }
            cell.onAwayPlayerTapped = { [weak self] in
                self?.viewModel.selectAwayPlayer(at: indexPath)
            }
            cell.onScoreTapped = { [weak self] in
                self?.viewModel.selectMatch(at: indexPath)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionView.elementKindSectionHeader,
              let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RoundHeaderView.identifier, for: indexPath) as? RoundHeaderView else {
            return UICollectionReusableView()
        }
        headerView.configure(roundName: sections[indexPath.section].roundName)
        return headerView
    }
}

// MARK: - UICollectionViewDelegate

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectMatch(at: indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let matchPresentation = sections[indexPath.section].matches[indexPath.item]
        let height: CGFloat = matchPresentation.usesBigCell ? 150 : 80
        return CGSize(width: collectionView.bounds.width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 50)
    }
}

// MARK: - HomeViewModelDelegate

extension HomeViewController: HomeViewModelDelegate {
    func handleOutput(_ output: HomeViewModelOutput) {
        switch output {
        case .showLoading(let isLoading):
            if isLoading {
                activityIndicator.startAnimating()
            } else {
                activityIndicator.stopAnimating()
                refreshControl.endRefreshing()
            }
            
        case .displaySections(let sections):
            self.sections = sections
            collectionView.reloadData()
            
        case .showError(let message):
            print("Error: \(message)")
            
        case .showEmptyState(let isEmpty):
            isEmptyState = isEmpty
            emptyStateLabel.isHidden = !isEmpty
            collectionView.reloadData()
        }
    }
    
    func navigate(to route: HomeRoute) {
        coordinator?.handle(route: route)
    }
}
