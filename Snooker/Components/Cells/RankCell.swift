//
//  RankCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

// MARK: - RankCell

final class RankCell: UICollectionViewCell {
    
    static let identifier = "RankCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let playerImageSize: PlayerImageSize = .medium
        static let nameFontSize: CGFloat = 17
        static let surnameFontSize: CGFloat = 20
        static let moneyFontSize: CGFloat = 14
        static let rankFontSize: CGFloat = 32
        static let flagFontSize: CGFloat = 18
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let contentSpacing: CGFloat = 12
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Player Image with Flag Badge
    private let playerImageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    private let flagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.flagFontSize)
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 12
        label.layer.masksToBounds = true
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.systemGray4.cgColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Player Info Stack (Name + Prize Money)
    private let playerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.nameFontSize)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let playerSurnameLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: Constants.surnameFontSize)
        label.textColor = .label
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let prizeMoneyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.moneyFontSize, weight: .medium)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var infoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [playerNameLabel, playerSurnameLabel, prizeMoneyLabel])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Rank Number (Right side, big)
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.rankFontSize, weight: .bold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        
        // Player image container
        containerView.addSubview(playerImageContainerView)
        playerImageContainerView.addSubview(playerImageView)
        playerImageContainerView.addSubview(flagLabel)
        
        // Info stack
        containerView.addSubview(infoStackView)
        
        // Rank label
        containerView.addSubview(rankLabel)
    }
    
    private func setupConstraints() {
        let imageSize = Constants.playerImageSize.dimension
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            // Player Image Container
            playerImageContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            playerImageContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            playerImageContainerView.widthAnchor.constraint(equalToConstant: imageSize),
            playerImageContainerView.heightAnchor.constraint(equalToConstant: imageSize),
            
            // Player Image
            playerImageView.topAnchor.constraint(equalTo: playerImageContainerView.topAnchor),
            playerImageView.leadingAnchor.constraint(equalTo: playerImageContainerView.leadingAnchor),
            playerImageView.trailingAnchor.constraint(equalTo: playerImageContainerView.trailingAnchor),
            playerImageView.bottomAnchor.constraint(equalTo: playerImageContainerView.bottomAnchor),
            
            // Flag Badge - bottom right corner
            flagLabel.trailingAnchor.constraint(equalTo: playerImageContainerView.trailingAnchor, constant: 4),
            flagLabel.bottomAnchor.constraint(equalTo: playerImageContainerView.bottomAnchor, constant: 4),
            flagLabel.widthAnchor.constraint(equalToConstant: 26),
            flagLabel.heightAnchor.constraint(equalToConstant: 26),
            
            // Info Stack
            infoStackView.leadingAnchor.constraint(equalTo: playerImageContainerView.trailingAnchor, constant: Constants.contentSpacing),
            infoStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            infoStackView.trailingAnchor.constraint(lessThanOrEqualTo: rankLabel.leadingAnchor, constant: -Constants.contentSpacing),
            
            // Rank Label
            rankLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            rankLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            rankLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            // Cell minimum height
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: imageSize + Constants.verticalPadding * 2)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: RankCellPresentation) {
        // Player Image
        playerImageView.configure(with: presentation.playerPhotoUrl)
        
        // Player Name
        playerNameLabel.text = presentation.playerName
        playerSurnameLabel.text = presentation.playerSurname
        
        // Flag
        if let flag = presentation.playerFlag {
            flagLabel.text = flag
            flagLabel.isHidden = false
        } else {
            flagLabel.isHidden = true
        }
        
        // Prize Money
        prizeMoneyLabel.text = presentation.prizeMoney
        
        // Rank
        rankLabel.text = "#\(presentation.position)"
        
        // Top 3 için özel renklendirme
        switch presentation.position {
        case 1:
            rankLabel.textColor = UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) // Gold
        case 2:
            rankLabel.textColor = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0) // Silver
        case 3:
            rankLabel.textColor = UIColor(red: 0.8, green: 0.5, blue: 0.2, alpha: 1.0) // Bronze
        default:
            rankLabel.textColor = .secondaryLabel
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerImageView.configure(with: nil)
        playerNameLabel.text = nil
        playerSurnameLabel.text = nil
        flagLabel.text = nil
        flagLabel.isHidden = true
        prizeMoneyLabel.text = nil
        rankLabel.text = nil
        rankLabel.textColor = .secondaryLabel
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct RankCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Single Cell Preview
            RankCellPreviewWrapper()
                .frame(height: 120)
                .previewDisplayName("Single Cell - Light")
            
            RankCellPreviewWrapper()
                .frame(height: 120)
                .preferredColorScheme(.dark)
                .previewDisplayName("Single Cell - Dark")
            
            // Multiple Cells in List
            RankCellListPreviewWrapper()
                .previewDisplayName("Cell List")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct RankCellPreviewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UICollectionViewCell {
        let cell = RankCell(frame: CGRect(x: 0, y: 0, width: 375, height: 120))
        cell.configure(with: RankCellPresentation.preview)
        return cell
    }
    
    func updateUIView(_ uiView: UICollectionViewCell, context: Context) {}
}

@available(iOS 13.0, *)
private struct RankCellListPreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = RankCellPreviewCollectionViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class RankCellPreviewCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let presentations = RankCellPresentation.previewList
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(RankCell.self, forCellWithReuseIdentifier: RankCell.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        title = "Rankings"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presentations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RankCell.identifier, for: indexPath) as? RankCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: presentations[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 120)
    }
}

#endif
