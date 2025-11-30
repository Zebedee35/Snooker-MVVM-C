//
//  ScoreCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.11.2025.
//

import UIKit

// MARK: - ScoreCell

/// Kompakt skor hücresi - Maç listelerinde kullanılır
/// Layout: | Photo | PlayerName | Score - Score | PlayerName | Photo |
final class ScoreCell: UITableViewCell {
    
    static let identifier = "ScoreCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let cellHeight: CGFloat = 64
        static let playerImageSize: PlayerImageSize = .small
        static let playerFontSize: CGFloat = 13
        static let scoreFontSize: CGFloat = 20
        static let statusFontSize: CGFloat = 10
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 6
        static let spacing: CGFloat = 8
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Home Player (Left side)
    private let homePlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    private let homePlayerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.playerFontSize, weight: .medium)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Score (Center)
    private let homeScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.scoreFontSize, weight: .bold)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = .systemFont(ofSize: Constants.scoreFontSize, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.scoreFontSize, weight: .bold)
        label.textColor = .label
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let matchStatusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.statusFontSize, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scoreStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [homeScoreLabel, scoreSeparatorLabel, awayScoreLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var centerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [scoreStackView, matchStatusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Away Player (Right side)
    private let awayPlayerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.playerFontSize, weight: .medium)
        label.textColor = .label
        label.textAlignment = .right
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayPlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    // Live indicator
    private let liveIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 4
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Callbacks
    
    var onHomePlayerTapped: (() -> Void)?
    var onAwayPlayerTapped: (() -> Void)?
    var onScoreTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        
        containerView.addSubview(homePlayerImageView)
        containerView.addSubview(homePlayerNameLabel)
        containerView.addSubview(centerStackView)
        containerView.addSubview(awayPlayerNameLabel)
        containerView.addSubview(awayPlayerImageView)
        containerView.addSubview(liveIndicatorView)
        
        setupGestures()
    }
    
    private func setupGestures() {
        // Home Player taps
        homePlayerImageView.isUserInteractionEnabled = true
        let homeImageTap = UITapGestureRecognizer(target: self, action: #selector(homePlayerTapped))
        homePlayerImageView.addGestureRecognizer(homeImageTap)
        
        homePlayerNameLabel.isUserInteractionEnabled = true
        let homeNameTap = UITapGestureRecognizer(target: self, action: #selector(homePlayerTapped))
        homePlayerNameLabel.addGestureRecognizer(homeNameTap)
        
        // Away Player taps
        awayPlayerImageView.isUserInteractionEnabled = true
        let awayImageTap = UITapGestureRecognizer(target: self, action: #selector(awayPlayerTapped))
        awayPlayerImageView.addGestureRecognizer(awayImageTap)
        
        awayPlayerNameLabel.isUserInteractionEnabled = true
        let awayNameTap = UITapGestureRecognizer(target: self, action: #selector(awayPlayerTapped))
        awayPlayerNameLabel.addGestureRecognizer(awayNameTap)
        
        // Score tap
        centerStackView.isUserInteractionEnabled = true
        let scoreTap = UITapGestureRecognizer(target: self, action: #selector(scoreTapped))
        centerStackView.addGestureRecognizer(scoreTap)
    }
    
    @objc private func homePlayerTapped() {
        onHomePlayerTapped?()
    }
    
    @objc private func awayPlayerTapped() {
        onAwayPlayerTapped?()
    }
    
    @objc private func scoreTapped() {
        onScoreTapped?()
    }
    
    private func setupConstraints() {
        _ = Constants.playerImageSize.dimension
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            containerView.heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.cellHeight),
            
            // Home Player Image (Left)
            homePlayerImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            homePlayerImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Home Player Name
            homePlayerNameLabel.leadingAnchor.constraint(equalTo: homePlayerImageView.trailingAnchor, constant: Constants.spacing),
            homePlayerNameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            homePlayerNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: centerStackView.leadingAnchor, constant: -Constants.spacing),
            
            // Center Stack (Score + Status)
            centerStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            centerStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            centerStackView.widthAnchor.constraint(greaterThanOrEqualToConstant: 80),
            
            // Away Player Name
            awayPlayerNameLabel.trailingAnchor.constraint(equalTo: awayPlayerImageView.leadingAnchor, constant: -Constants.spacing),
            awayPlayerNameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            awayPlayerNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: centerStackView.trailingAnchor, constant: Constants.spacing),
            
            // Away Player Image (Right)
            awayPlayerImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            awayPlayerImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Live Indicator (top-right corner of container)
            liveIndicatorView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            liveIndicatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            liveIndicatorView.widthAnchor.constraint(equalToConstant: 8),
            liveIndicatorView.heightAnchor.constraint(equalToConstant: 8),
        ])
        
        // İsim labelları için eşit genişlik
        homePlayerNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        awayPlayerNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        homePlayerNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        awayPlayerNameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: LiveScoreCellPresentation) {
        // Home Player
        homePlayerImageView.configure(with: presentation.homePlayerPhotoUrl)
        homePlayerNameLabel.text = "\(presentation.homePlayerName.prefix(1)). \(presentation.homePlayerSurname)"
        
        // Away Player
        awayPlayerImageView.configure(with: presentation.awayPlayerPhotoUrl)
        awayPlayerNameLabel.text = "\(presentation.awayPlayerName.prefix(1)). \(presentation.awayPlayerSurname)"
        
        // Scores
        homeScoreLabel.text = String(presentation.homePlayerScore)
        awayScoreLabel.text = String(presentation.awayPlayerScore)
        
        // Score renkleri
        updateScoreColors(homeScore: presentation.homePlayerScore, awayScore: presentation.awayPlayerScore)
        
        // Status
        let status = presentation.matchStatus.lowercased()
        if status == "live" {
            matchStatusLabel.text = "LIVE"
            matchStatusLabel.textColor = .systemRed
            liveIndicatorView.isHidden = false
            startLiveAnimation()
        } else if status == "completed" || status == "done" {
            matchStatusLabel.text = "Completed"
            matchStatusLabel.textColor = .secondaryLabel
            liveIndicatorView.isHidden = true
            stopLiveAnimation()
        } else {
            matchStatusLabel.text = presentation.matchStatus
            matchStatusLabel.textColor = .secondaryLabel
            liveIndicatorView.isHidden = true
            stopLiveAnimation()
        }
    }
    
    // MARK: - Helpers
    
    private func updateScoreColors(homeScore: Int, awayScore: Int) {
        let winningColor = UIColor.systemGreen
        let normalColor = UIColor.label
        let losingColor = UIColor.secondaryLabel
        
        if homeScore > awayScore {
            homeScoreLabel.textColor = winningColor
            awayScoreLabel.textColor = losingColor
        } else if awayScore > homeScore {
            homeScoreLabel.textColor = losingColor
            awayScoreLabel.textColor = winningColor
        } else {
            homeScoreLabel.textColor = normalColor
            awayScoreLabel.textColor = normalColor
        }
    }
    
    private func startLiveAnimation() {
        liveIndicatorView.alpha = 1.0
        UIView.animate(withDuration: 0.8, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.liveIndicatorView.alpha = 0.3
        }
    }
    
    private func stopLiveAnimation() {
        liveIndicatorView.layer.removeAllAnimations()
        liveIndicatorView.alpha = 1.0
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        homePlayerImageView.configure(with: nil)
        awayPlayerImageView.configure(with: nil)
        homePlayerNameLabel.text = nil
        awayPlayerNameLabel.text = nil
        homeScoreLabel.text = nil
        awayScoreLabel.text = nil
        matchStatusLabel.text = nil
        matchStatusLabel.textColor = .secondaryLabel
        liveIndicatorView.isHidden = true
        stopLiveAnimation()
        onHomePlayerTapped = nil
        onAwayPlayerTapped = nil
        onScoreTapped = nil
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct ScoreCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Single Cell Preview
            ScoreCellPreviewWrapper()
                .frame(height: 70)
                .previewDisplayName("Single Cell - Light")
            
            ScoreCellPreviewWrapper()
                .frame(height: 70)
                .preferredColorScheme(.dark)
                .previewDisplayName("Single Cell - Dark")
            
            // Multiple Cells in List
            ScoreCellListPreviewWrapper()
                .previewDisplayName("Cell List")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct ScoreCellPreviewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UITableViewCell {
        let cell = ScoreCell(style: .default, reuseIdentifier: ScoreCell.identifier)
        cell.configure(with: LiveScoreCellPresentation.preview)
        return cell
    }
    
    func updateUIView(_ uiView: UITableViewCell, context: Context) {}
}

@available(iOS 13.0, *)
private struct ScoreCellListPreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITableViewController {
        let controller = ScoreCellPreviewTableViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UITableViewController, context: Context) {}
}

private class ScoreCellPreviewTableViewController: UITableViewController {
    private let presentations = LiveScoreCellPresentation.previewList
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ScoreCell.self, forCellReuseIdentifier: ScoreCell.identifier)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 70
        title = "Scores"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return presentations.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ScoreCell.identifier, for: indexPath) as? ScoreCell else {
            return UITableViewCell()
        }
        cell.configure(with: presentations[indexPath.row])
        return cell
    }
}

#endif
