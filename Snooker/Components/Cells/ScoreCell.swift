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
final class ScoreCell: UICollectionViewCell {
    
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
        label.font = AppFont.medium(size: Constants.playerFontSize)
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
        label.font = AppFont.bold(size: Constants.scoreFontSize)
        label.textColor = .label
        label.textAlignment = .right
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = AppFont.medium(size: Constants.scoreFontSize)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: Constants.scoreFontSize)
        label.textColor = .label
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let matchStatusLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.medium(size: Constants.statusFontSize)
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
        label.font = AppFont.medium(size: Constants.playerFontSize)
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
        
        // Scheduled maçlarda skor yerine tarih göster
        if presentation.isScheduled {
            // Skor label'larını tarih/saat için kullan
            homeScoreLabel.isHidden = false
            awayScoreLabel.isHidden = false
            scoreSeparatorLabel.isHidden = true
            
            // Stack'i dikey yap (tarih üstte, saat altta)
            scoreStackView.axis = .vertical
            scoreStackView.spacing = 0
            
            // Tarih kısmı (bugün değilse)
            if let datePart = presentation.formattedDatePart {
                homeScoreLabel.text = datePart
                homeScoreLabel.font = AppFont.medium(size: Constants.scoreFontSize - 8)
                homeScoreLabel.textColor = .secondaryLabel
                homeScoreLabel.textAlignment = .center
            } else {
                homeScoreLabel.text = ""
            }
            
            // Saat kısmı
            awayScoreLabel.text = presentation.formattedTimePart ?? "TBD"
            awayScoreLabel.font = AppFont.semiBold(size: Constants.scoreFontSize - 2)
            awayScoreLabel.textColor = .label
            awayScoreLabel.textAlignment = .center
            
            matchStatusLabel.text = ""
            liveIndicatorView.isHidden = true
            stopLiveAnimation()
        } else {
            // Stack'i yatay yap (normal skor görünümü)
            scoreStackView.axis = .horizontal
            scoreStackView.spacing = 4
            
            // Skor label'larını göster
            homeScoreLabel.isHidden = false
            awayScoreLabel.isHidden = false
            scoreSeparatorLabel.isHidden = false
            
            // Scores - fontları resetle
            homeScoreLabel.font = AppFont.bold(size: Constants.scoreFontSize)
            homeScoreLabel.textAlignment = .right
            awayScoreLabel.font = AppFont.bold(size: Constants.scoreFontSize)
            awayScoreLabel.textAlignment = .left
            homeScoreLabel.text = String(presentation.homePlayerScore)
            awayScoreLabel.text = String(presentation.awayPlayerScore)
            
            // Score renkleri
            updateScoreColors(homeScore: presentation.homePlayerScore, awayScore: presentation.awayPlayerScore)
            
            // Status
            matchStatusLabel.font = AppFont.medium(size: Constants.statusFontSize)
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
        homeScoreLabel.isHidden = false
        awayScoreLabel.text = nil
        awayScoreLabel.isHidden = false
        scoreSeparatorLabel.isHidden = false
        matchStatusLabel.text = nil
        matchStatusLabel.textColor = .secondaryLabel
        matchStatusLabel.font = AppFont.medium(size: Constants.statusFontSize)
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
            // Live Match
            ScoreCellPreviewWrapper(presentation: .preview)
                .frame(height: 70)
                .previewDisplayName("Live Match")
            
            // Scheduled - Farklı gün
            ScoreCellPreviewWrapper(presentation: .previewScheduled)
                .frame(height: 70)
                .previewDisplayName("Scheduled - Different Day")
            
            // Scheduled - Bugün
            ScoreCellPreviewWrapper(presentation: .previewScheduledToday)
                .frame(height: 70)
                .previewDisplayName("Scheduled - Today")
            
            // Multiple Cells in List
            ScoreCellListPreviewWrapper()
                .previewDisplayName("Cell List")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct ScoreCellPreviewWrapper: UIViewRepresentable {
    var presentation: LiveScoreCellPresentation = .preview
    
    func makeUIView(context: Context) -> UICollectionViewCell {
        let cell = ScoreCell(frame: CGRect(x: 0, y: 0, width: 375, height: 70))
        cell.configure(with: presentation)
        return cell
    }
    
    func updateUIView(_ uiView: UICollectionViewCell, context: Context) {}
}

@available(iOS 13.0, *)
private struct ScoreCellListPreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = ScoreCellPreviewCollectionViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class ScoreCellPreviewCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let presentations = LiveScoreCellPresentation.previewList
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(ScoreCell.self, forCellWithReuseIdentifier: ScoreCell.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        title = "Scores"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presentations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ScoreCell.identifier, for: indexPath) as? ScoreCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: presentations[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 70)
    }
}

#endif
