//
//  HeadToHeadViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

final class HeadToHeadViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 16
        static let playerImageSize: CGFloat = 80
        static let matchCellHeight: CGFloat = 90
    }
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Header - Players vs
    private let headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Player 1 (Left)
    private let player1ImageView: PlayerImageView = {
        let imageView = PlayerImageView(size: .large)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let player1NameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: 14)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let player1FlagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // VS Label
    private let vsLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.Common.versus
        label.font = AppFont.bold(size: 20)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Win Stats
    private let winsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let player1WinsLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 24)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let winsSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = AppFont.medium(size: 20)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let player2WinsLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 24)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.text = "0"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Player 2 (Right)
    private let player2ImageView: PlayerImageView = {
        let imageView = PlayerImageView(size: .large)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let player2NameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: 14)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let player2FlagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Matches Section
    private let matchesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.HeadToHead.allMatches
        label.font = AppFont.semiBold(size: 18)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private lazy var matchesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 12
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(HeadToHeadCell.self, forCellWithReuseIdentifier: HeadToHeadCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = L10n.HeadToHead.empty
        label.font = AppFont.regular(size: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Close Button
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private var viewModel: HeadToHeadViewModelProtocol
    private var matchPresentations: [HeadToHeadMatchPresentation] = []
    private var matchesCollectionViewHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Init
    
    init(viewModel: HeadToHeadViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configureHeader()
        
        viewModel.delegate = self
        viewModel.load()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(closeButton)
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        // Header
        contentView.addSubview(headerContainerView)
        
        // Player 1
        headerContainerView.addSubview(player1ImageView)
        headerContainerView.addSubview(player1NameLabel)
        headerContainerView.addSubview(player1FlagLabel)
        
        // VS and Wins
        headerContainerView.addSubview(vsLabel)
        headerContainerView.addSubview(winsContainerView)
        winsContainerView.addSubview(player1WinsLabel)
        winsContainerView.addSubview(winsSeparatorLabel)
        winsContainerView.addSubview(player2WinsLabel)
        
        // Player 2
        headerContainerView.addSubview(player2ImageView)
        headerContainerView.addSubview(player2NameLabel)
        headerContainerView.addSubview(player2FlagLabel)
        
        // Matches
        contentView.addSubview(matchesTitleLabel)
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(matchesCollectionView)
        contentView.addSubview(emptyLabel)
    }
    
    private func setupConstraints() {
        let heightConstraint = matchesCollectionView.heightAnchor.constraint(equalToConstant: 0)
        matchesCollectionViewHeightConstraint = heightConstraint
        
        NSLayoutConstraint.activate([
            // Close button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 30),
            closeButton.heightAnchor.constraint(equalToConstant: 30),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header container
            headerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalPadding),
            headerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            headerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Player 1
            player1ImageView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 20),
            player1ImageView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 24),
            player1ImageView.widthAnchor.constraint(equalToConstant: Constants.playerImageSize),
            player1ImageView.heightAnchor.constraint(equalToConstant: Constants.playerImageSize),
            
            player1FlagLabel.topAnchor.constraint(equalTo: player1ImageView.bottomAnchor, constant: 8),
            player1FlagLabel.centerXAnchor.constraint(equalTo: player1ImageView.centerXAnchor),
            
            player1NameLabel.topAnchor.constraint(equalTo: player1FlagLabel.bottomAnchor, constant: 4),
            player1NameLabel.centerXAnchor.constraint(equalTo: player1ImageView.centerXAnchor),
            player1NameLabel.widthAnchor.constraint(equalToConstant: 100),
            player1NameLabel.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -20),
            
            // VS & Wins
            vsLabel.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            vsLabel.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 30),
            
            winsContainerView.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            winsContainerView.topAnchor.constraint(equalTo: vsLabel.bottomAnchor, constant: 12),
            winsContainerView.widthAnchor.constraint(equalToConstant: 90),
            winsContainerView.heightAnchor.constraint(equalToConstant: 40),
            
            player1WinsLabel.leadingAnchor.constraint(equalTo: winsContainerView.leadingAnchor, constant: 8),
            player1WinsLabel.centerYAnchor.constraint(equalTo: winsContainerView.centerYAnchor),
            player1WinsLabel.widthAnchor.constraint(equalToConstant: 28),
            
            winsSeparatorLabel.centerXAnchor.constraint(equalTo: winsContainerView.centerXAnchor),
            winsSeparatorLabel.centerYAnchor.constraint(equalTo: winsContainerView.centerYAnchor),
            
            player2WinsLabel.trailingAnchor.constraint(equalTo: winsContainerView.trailingAnchor, constant: -8),
            player2WinsLabel.centerYAnchor.constraint(equalTo: winsContainerView.centerYAnchor),
            player2WinsLabel.widthAnchor.constraint(equalToConstant: 28),
            
            // Player 2
            player2ImageView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 20),
            player2ImageView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -24),
            player2ImageView.widthAnchor.constraint(equalToConstant: Constants.playerImageSize),
            player2ImageView.heightAnchor.constraint(equalToConstant: Constants.playerImageSize),
            
            player2FlagLabel.topAnchor.constraint(equalTo: player2ImageView.bottomAnchor, constant: 8),
            player2FlagLabel.centerXAnchor.constraint(equalTo: player2ImageView.centerXAnchor),
            
            player2NameLabel.topAnchor.constraint(equalTo: player2FlagLabel.bottomAnchor, constant: 4),
            player2NameLabel.centerXAnchor.constraint(equalTo: player2ImageView.centerXAnchor),
            player2NameLabel.widthAnchor.constraint(equalToConstant: 100),
            
            // Matches Title
            matchesTitleLabel.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: 24),
            matchesTitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            
            loadingIndicator.centerYAnchor.constraint(equalTo: matchesTitleLabel.centerYAnchor),
            loadingIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Collection View
            matchesCollectionView.topAnchor.constraint(equalTo: matchesTitleLabel.bottomAnchor, constant: 16),
            matchesCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            matchesCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            matchesCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalPadding),
            heightConstraint,
            
            // Empty label
            emptyLabel.centerXAnchor.constraint(equalTo: matchesCollectionView.centerXAnchor),
            emptyLabel.topAnchor.constraint(equalTo: matchesTitleLabel.bottomAnchor, constant: 40)
        ])
    }
    
    private func configureHeader() {
        let header = viewModel.headerPresentation
        
        player1ImageView.configure(with: header.player1PhotoUrl)
        player1NameLabel.text = header.player1FullName
        player1FlagLabel.text = header.player1Flag
        
        player2ImageView.configure(with: header.player2PhotoUrl)
        player2NameLabel.text = header.player2FullName
        player2FlagLabel.text = header.player2Flag
    }
    
    private func updateMatchesCollectionViewHeight() {
        let itemCount = matchPresentations.count
        let totalHeight = CGFloat(itemCount) * (Constants.matchCellHeight + 12)
        matchesCollectionViewHeightConstraint?.constant = max(totalHeight, 0)
        view.layoutIfNeeded()
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - HeadToHeadViewModelDelegate

extension HeadToHeadViewController: HeadToHeadViewModelDelegate {
    func handleOutput(_ output: HeadToHeadViewModelOutput) {
        switch output {
        case .showLoading(let isLoading):
            if isLoading {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
            
        case .displayMatches(let presentations):
            matchPresentations = presentations
            emptyLabel.isHidden = true
            matchesCollectionView.isHidden = false
            matchesCollectionView.reloadData()
            updateMatchesCollectionViewHeight()
            
        case .updateHeader(let header):
            player1WinsLabel.text = "\(header.player1Wins)"
            player2WinsLabel.text = "\(header.player2Wins)"
            
        case .showError(let message):
            emptyLabel.text = L10n.Common.errorWithReason(message)
            emptyLabel.isHidden = false
            matchesCollectionView.isHidden = true
            
        case .showEmpty:
            emptyLabel.isHidden = false
            matchesCollectionView.isHidden = true
        }
    }
}

// MARK: - UICollectionViewDataSource

extension HeadToHeadViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        matchPresentations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HeadToHeadCell.reuseIdentifier,
            for: indexPath
        ) as? HeadToHeadCell else {
            return UICollectionViewCell()
        }
        
        let presentation = matchPresentations[indexPath.item]
        cell.configure(with: presentation)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension HeadToHeadViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        return CGSize(width: width, height: Constants.matchCellHeight)
    }
}
