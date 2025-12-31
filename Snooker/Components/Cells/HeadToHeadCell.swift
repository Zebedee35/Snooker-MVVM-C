//
//  HeadToHeadCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

/// Head-to-Head ekranında maç geçmişini gösteren cell
/// Layout:
/// [Tournament Info - Year, Name, Round]
/// [WIN/LOSE]  [Score1 - Score2]  [WIN/LOSE]
final class HeadToHeadCell: UICollectionViewCell {
    
    static let reuseIdentifier = "HeadToHeadCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 12
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Tournament Info
    private let tournamentLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Score Row
    private let scoreRowStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Left Result (Player 1)
    private let player1ResultLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Score Container
    private let scoreContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .tertiarySystemBackground
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let player1ScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = AppFont.medium(size: 18)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let player2ScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Right Result (Player 2)
    private let player2ResultLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 14)
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
        contentView.addSubview(containerView)
        containerView.addSubview(tournamentLabel)
        containerView.addSubview(scoreRowStackView)
        
        // Score container with labels
        scoreContainerView.addSubview(player1ScoreLabel)
        scoreContainerView.addSubview(scoreSeparatorLabel)
        scoreContainerView.addSubview(player2ScoreLabel)
        
        // Stack view items
        scoreRowStackView.addArrangedSubview(player1ResultLabel)
        scoreRowStackView.addArrangedSubview(scoreContainerView)
        scoreRowStackView.addArrangedSubview(player2ResultLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            // Tournament info
            tournamentLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.verticalPadding),
            tournamentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            tournamentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Score row
            scoreRowStackView.topAnchor.constraint(equalTo: tournamentLabel.bottomAnchor, constant: 10),
            scoreRowStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            scoreRowStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.verticalPadding),
            
            // Result labels width
            player1ResultLabel.widthAnchor.constraint(equalToConstant: 50),
            player2ResultLabel.widthAnchor.constraint(equalToConstant: 50),
            
            // Score container
            scoreContainerView.widthAnchor.constraint(equalToConstant: 100),
            scoreContainerView.heightAnchor.constraint(equalToConstant: 36),
            
            player1ScoreLabel.leadingAnchor.constraint(equalTo: scoreContainerView.leadingAnchor, constant: 8),
            player1ScoreLabel.centerYAnchor.constraint(equalTo: scoreContainerView.centerYAnchor),
            player1ScoreLabel.widthAnchor.constraint(equalToConstant: 30),
            
            scoreSeparatorLabel.centerXAnchor.constraint(equalTo: scoreContainerView.centerXAnchor),
            scoreSeparatorLabel.centerYAnchor.constraint(equalTo: scoreContainerView.centerYAnchor),
            
            player2ScoreLabel.trailingAnchor.constraint(equalTo: scoreContainerView.trailingAnchor, constant: -8),
            player2ScoreLabel.centerYAnchor.constraint(equalTo: scoreContainerView.centerYAnchor),
            player2ScoreLabel.widthAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: HeadToHeadMatchPresentation) {
        tournamentLabel.text = presentation.tournamentInfo
        
        player1ScoreLabel.text = "\(presentation.player1Score)"
        player2ScoreLabel.text = "\(presentation.player2Score)"
        
        let didPlayer1Win = presentation.didPlayer1Win
        
        // Result labels
        player1ResultLabel.text = didPlayer1Win ? "WIN" : "LOSE"
        player1ResultLabel.textColor = didPlayer1Win ? .systemGreen : .systemRed
        
        player2ResultLabel.text = didPlayer1Win ? "LOSE" : "WIN"
        player2ResultLabel.textColor = didPlayer1Win ? .systemRed : .systemGreen
        
        // Score colors
        player1ScoreLabel.textColor = didPlayer1Win ? .systemGreen : .label
        player2ScoreLabel.textColor = didPlayer1Win ? .label : .systemGreen
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tournamentLabel.text = nil
        player1ScoreLabel.text = nil
        player2ScoreLabel.text = nil
        player1ResultLabel.text = nil
        player2ResultLabel.text = nil
    }
}
