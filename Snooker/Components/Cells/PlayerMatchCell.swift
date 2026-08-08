//
//  PlayerMatchCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import UIKit

/// Player Detail Modal'da son maçları gösteren cell
/// Layout: [Round] | [CurrentScore - OpponentScore] | [Opponent Flag + Name + Photo]
final class PlayerMatchCell: UICollectionViewCell {
    
    static let reuseIdentifier = "PlayerMatchCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 10
        static let imageSize: CGFloat = 36
        static let scoreWidth: CGFloat = 70
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Left - Round
    private let roundLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Center - Score
    private let scoreContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let currentScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = AppFont.medium(size: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let opponentScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 18)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Right - Opponent
    private let opponentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let opponentInfoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .trailing
        return stack
    }()
    
    private let opponentNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.medium(size: 13)
        label.textColor = .label
        label.textAlignment = .right
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let opponentFlagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 16)
        return label
    }()
    
    private let opponentImageView: PlayerImageView = {
        let imageView = PlayerImageView(size: .small)
        return imageView
    }()
    
    // Win/Loss indicator
    private let resultIndicatorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        contentView.addSubview(containerView)
        
        // Left indicator
        containerView.addSubview(resultIndicatorView)
        
        // Round
        containerView.addSubview(roundLabel)
        
        // Score
        containerView.addSubview(scoreContainerView)
        scoreContainerView.addSubview(currentScoreLabel)
        scoreContainerView.addSubview(scoreSeparatorLabel)
        scoreContainerView.addSubview(opponentScoreLabel)
        
        // Opponent
        containerView.addSubview(opponentStackView)
        opponentInfoStackView.addArrangedSubview(opponentNameLabel)
        opponentInfoStackView.addArrangedSubview(opponentFlagLabel)
        opponentStackView.addArrangedSubview(opponentInfoStackView)
        opponentStackView.addArrangedSubview(opponentImageView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Result indicator (left edge)
            resultIndicatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            resultIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor),
            resultIndicatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            resultIndicatorView.widthAnchor.constraint(equalToConstant: 4),
            
            // Round (left side)
            roundLabel.leadingAnchor.constraint(equalTo: resultIndicatorView.trailingAnchor, constant: Constants.horizontalPadding),
            roundLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            roundLabel.widthAnchor.constraint(equalToConstant: 55),
            
            // Score (after round label)
            scoreContainerView.leadingAnchor.constraint(equalTo: roundLabel.trailingAnchor, constant: 8),
            scoreContainerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            scoreContainerView.widthAnchor.constraint(equalToConstant: Constants.scoreWidth),
            scoreContainerView.heightAnchor.constraint(equalToConstant: 32),
            
            currentScoreLabel.leadingAnchor.constraint(equalTo: scoreContainerView.leadingAnchor),
            currentScoreLabel.centerYAnchor.constraint(equalTo: scoreContainerView.centerYAnchor),
            currentScoreLabel.widthAnchor.constraint(equalToConstant: 24),
            
            scoreSeparatorLabel.centerXAnchor.constraint(equalTo: scoreContainerView.centerXAnchor),
            scoreSeparatorLabel.centerYAnchor.constraint(equalTo: scoreContainerView.centerYAnchor),
            
            opponentScoreLabel.trailingAnchor.constraint(equalTo: scoreContainerView.trailingAnchor),
            opponentScoreLabel.centerYAnchor.constraint(equalTo: scoreContainerView.centerYAnchor),
            opponentScoreLabel.widthAnchor.constraint(equalToConstant: 24),
            
            // Opponent (right side)
            opponentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            opponentStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            opponentStackView.leadingAnchor.constraint(greaterThanOrEqualTo: scoreContainerView.trailingAnchor, constant: 12)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: PlayerMatchCellPresentation) {
        // Round
        roundLabel.text = RoundName.localized(presentation.round)
        
        // Score
        currentScoreLabel.text = "\(presentation.currentPlayerScore)"
        opponentScoreLabel.text = "\(presentation.opponentScore)"
        
        // Colors based on win/loss
        let didWin = presentation.didCurrentPlayerWin
        resultIndicatorView.backgroundColor = didWin ? .systemGreen : .systemRed
        currentScoreLabel.textColor = didWin ? .systemGreen : .label
        opponentScoreLabel.textColor = didWin ? .label : .systemRed
        
        // Opponent
        opponentNameLabel.text = presentation.opponentFullName
        opponentFlagLabel.text = presentation.opponentFlag
        opponentImageView.configure(with: presentation.opponentPhotoUrl)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        roundLabel.text = nil
        currentScoreLabel.text = nil
        opponentScoreLabel.text = nil
        opponentNameLabel.text = nil
        opponentFlagLabel.text = nil
        opponentImageView.configure(with: nil)
    }
}
