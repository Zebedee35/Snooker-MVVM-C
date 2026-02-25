//
//  LiveScoreCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 25.11.2025.
//

import UIKit

// MARK: - LiveScoreCell

final class LiveScoreCell: UICollectionViewCell {
    
    static let identifier = "LiveScoreCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let frameHeight: CGFloat = 120
        static let playerImageSize: PlayerImageSize = .medium
        static let playerFontSize: CGFloat = 14
        static let rankFontSize: CGFloat = 11
        static let flagFontSize: CGFloat = 16
        static let scoreFontSize: CGFloat = 36
        static let statusFontSize: CGFloat = 14
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let playerStackSpacing: CGFloat = 8
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = false
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Home Player Views
    private let homePlayerImageContainerView: UIView = {
        let view = UIView()
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let homePlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    private let homePlayerFlagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: Constants.flagFontSize)
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homePlayerRankLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 11)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .systemGray
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homePlayerNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: Constants.playerFontSize)
        label.textColor = .label
        label.textAlignment = .left
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        label.clipsToBounds = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Away Player Views
    private let awayPlayerImageContainerView: UIView = {
        let view = UIView()
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let awayPlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    private let awayPlayerFlagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: Constants.flagFontSize)
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayPlayerRankLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 11)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .systemGray
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayPlayerNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: Constants.playerFontSize)
        label.textColor = .label
        label.textAlignment = .right
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        label.clipsToBounds = false
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // Score Views
    private let homeScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: Constants.scoreFontSize)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = AppFont.regular(size: Constants.scoreFontSize)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayScoreLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: Constants.scoreFontSize)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scoreStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [homeScoreLabel, scoreSeparatorLabel, awayScoreLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let matchStatusLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: Constants.statusFontSize)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let liveIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let liveLabel: UILabel = {
        let label = UILabel()
        label.text = "LIVE"
        label.font = AppFont.bold(size: 10)
        label.textColor = .systemRed
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var liveContainerView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [liveIndicatorView, liveLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()
    
    private lazy var centerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [liveContainerView, scoreStackView, matchStatusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [homePlayerImageContainerView, centerStackView, awayPlayerImageContainerView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var namesStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [homePlayerNameLabel, awayPlayerNameLabel])
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.clipsToBounds = false
        stack.setContentHuggingPriority(.required, for: .vertical)
        stack.setContentCompressionResistancePriority(.required, for: .vertical)
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var rootStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [mainStackView, namesStackView])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 8
        stack.clipsToBounds = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
        clipsToBounds = false
        contentView.clipsToBounds = false
        
        contentView.addSubview(containerView)
        containerView.addSubview(rootStackView)
        
        // Home player image container setup
        homePlayerImageContainerView.addSubview(homePlayerImageView)
        homePlayerImageContainerView.addSubview(homePlayerFlagLabel)
        homePlayerImageContainerView.addSubview(homePlayerRankLabel)
        
        // Away player image container setup
        awayPlayerImageContainerView.addSubview(awayPlayerImageView)
        awayPlayerImageContainerView.addSubview(awayPlayerFlagLabel)
        awayPlayerImageContainerView.addSubview(awayPlayerRankLabel)
        
        setupGestures()
    }
    
    private func setupGestures() {
        // Home Player taps (image container + name)
        homePlayerImageContainerView.isUserInteractionEnabled = true
        let homeImageTap = UITapGestureRecognizer(target: self, action: #selector(homePlayerTapped))
        homePlayerImageContainerView.addGestureRecognizer(homeImageTap)
        
        homePlayerNameLabel.isUserInteractionEnabled = true
        let homeNameTap = UITapGestureRecognizer(target: self, action: #selector(homePlayerTapped))
        homePlayerNameLabel.addGestureRecognizer(homeNameTap)
        
        // Away Player taps (image container + name)
        awayPlayerImageContainerView.isUserInteractionEnabled = true
        let awayImageTap = UITapGestureRecognizer(target: self, action: #selector(awayPlayerTapped))
        awayPlayerImageContainerView.addGestureRecognizer(awayImageTap)
        
        awayPlayerNameLabel.isUserInteractionEnabled = true
        let awayNameTap = UITapGestureRecognizer(target: self, action: #selector(awayPlayerTapped))
        awayPlayerNameLabel.addGestureRecognizer(awayNameTap)
        
        // Score tap (center stack)
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
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Root Stack (contains mainStack + namesStack)
            rootStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.verticalPadding),
            rootStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            rootStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            rootStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.verticalPadding),
            
            // Names stack needs minimum height for text with descenders
            namesStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
            
            // Home Player Image Container
            homePlayerImageContainerView.widthAnchor.constraint(equalToConstant: Constants.playerImageSize.dimension),
            homePlayerImageContainerView.heightAnchor.constraint(equalToConstant: Constants.playerImageSize.dimension),
            
            homePlayerImageView.topAnchor.constraint(equalTo: homePlayerImageContainerView.topAnchor),
            homePlayerImageView.leadingAnchor.constraint(equalTo: homePlayerImageContainerView.leadingAnchor),
            homePlayerImageView.trailingAnchor.constraint(equalTo: homePlayerImageContainerView.trailingAnchor),
            homePlayerImageView.bottomAnchor.constraint(equalTo: homePlayerImageContainerView.bottomAnchor),
            
            // Home Player Flag - bottom right corner, overlapping image
            homePlayerFlagLabel.trailingAnchor.constraint(equalTo: homePlayerImageContainerView.trailingAnchor, constant: 2),
            homePlayerFlagLabel.bottomAnchor.constraint(equalTo: homePlayerImageContainerView.bottomAnchor, constant: 2),
            homePlayerFlagLabel.widthAnchor.constraint(equalToConstant: 22),
            homePlayerFlagLabel.heightAnchor.constraint(equalToConstant: 22),
            
            // Home Player Rank - top left corner, overlapping image
            homePlayerRankLabel.leadingAnchor.constraint(equalTo: homePlayerImageContainerView.leadingAnchor, constant: -4),
            homePlayerRankLabel.topAnchor.constraint(equalTo: homePlayerImageContainerView.topAnchor, constant: -4),
            homePlayerRankLabel.widthAnchor.constraint(equalToConstant: 22),
            homePlayerRankLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Away Player Image Container
            awayPlayerImageContainerView.widthAnchor.constraint(equalToConstant: Constants.playerImageSize.dimension),
            awayPlayerImageContainerView.heightAnchor.constraint(equalToConstant: Constants.playerImageSize.dimension),
            
            awayPlayerImageView.topAnchor.constraint(equalTo: awayPlayerImageContainerView.topAnchor),
            awayPlayerImageView.leadingAnchor.constraint(equalTo: awayPlayerImageContainerView.leadingAnchor),
            awayPlayerImageView.trailingAnchor.constraint(equalTo: awayPlayerImageContainerView.trailingAnchor),
            awayPlayerImageView.bottomAnchor.constraint(equalTo: awayPlayerImageContainerView.bottomAnchor),
            
            // Away Player Flag - bottom right corner, overlapping image
            awayPlayerFlagLabel.trailingAnchor.constraint(equalTo: awayPlayerImageContainerView.trailingAnchor, constant: 2),
            awayPlayerFlagLabel.bottomAnchor.constraint(equalTo: awayPlayerImageContainerView.bottomAnchor, constant: 2),
            awayPlayerFlagLabel.widthAnchor.constraint(equalToConstant: 22),
            awayPlayerFlagLabel.heightAnchor.constraint(equalToConstant: 22),
            
            // Away Player Rank - top left corner, overlapping image
            awayPlayerRankLabel.leadingAnchor.constraint(equalTo: awayPlayerImageContainerView.leadingAnchor, constant: -4),
            awayPlayerRankLabel.topAnchor.constraint(equalTo: awayPlayerImageContainerView.topAnchor, constant: -4),
            awayPlayerRankLabel.widthAnchor.constraint(equalToConstant: 22),
            awayPlayerRankLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Live Indicator
            liveIndicatorView.widthAnchor.constraint(equalToConstant: 10),
            liveIndicatorView.heightAnchor.constraint(equalToConstant: 10),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: LiveScoreCellPresentation) {
        // Home Player
        homePlayerImageView.configure(with: presentation.homePlayerPhotoUrl)
        homePlayerNameLabel.attributedText = createPlayerNameAttributedString(
            firstName: presentation.homePlayerName,
            surname: presentation.homePlayerSurname,
            flagEmoji: presentation.homePlayerFlag
        )
        
        // Home Player Flag
        if let flag = presentation.homePlayerFlag {
            homePlayerFlagLabel.text = flag
            homePlayerFlagLabel.isHidden = false
        } else {
            homePlayerFlagLabel.isHidden = true
        }
        
        // Home Player Rank
        if let rank = presentation.homePlayerRank {
            homePlayerRankLabel.text = "\(rank)"
            homePlayerRankLabel.isHidden = false
        } else {
            homePlayerRankLabel.isHidden = true
        }
        
        // Away Player
        awayPlayerImageView.configure(with: presentation.awayPlayerPhotoUrl)
        awayPlayerNameLabel.attributedText = createPlayerNameAttributedString(
            firstName: presentation.awayPlayerName,
            surname: presentation.awayPlayerSurname,
            flagEmoji: presentation.awayPlayerFlag
        )
        
        // Away Player Flag
        if let flag = presentation.awayPlayerFlag {
            awayPlayerFlagLabel.text = flag
            awayPlayerFlagLabel.isHidden = false
        } else {
            awayPlayerFlagLabel.isHidden = true
        }
        
        // Away Player Rank
        if let rank = presentation.awayPlayerRank {
            awayPlayerRankLabel.text = "\(rank)"
            awayPlayerRankLabel.isHidden = false
        } else {
            awayPlayerRankLabel.isHidden = true
        }
        
        // Scheduled maçlarda skor yerine tarih/saat göster
        if presentation.isScheduled {
            // Skor label'larını tarih/saat için yeniden kullan
            homeScoreLabel.isHidden = false
            awayScoreLabel.isHidden = false
            scoreSeparatorLabel.isHidden = true
            
            // Stack'i dikey yap (tarih üstte, saat altta)
            scoreStackView.axis = .vertical
            scoreStackView.spacing = 2
            
            // Tarih kısmı (bugün değilse)
            if let datePart = presentation.formattedDatePart {
                homeScoreLabel.text = datePart
                homeScoreLabel.font = AppFont.medium(size: Constants.scoreFontSize - 14)
                homeScoreLabel.textColor = .secondaryLabel
                homeScoreLabel.textAlignment = .center
            } else {
                homeScoreLabel.text = ""
            }
            
            // Saat kısmı
            awayScoreLabel.text = presentation.formattedTimePart ?? "TBD"
            awayScoreLabel.font = AppFont.semiBold(size: Constants.scoreFontSize - 8)
            awayScoreLabel.textColor = .label
            awayScoreLabel.textAlignment = .center
            
            matchStatusLabel.text = ""
            stopLiveAnimation()
        } else {
            // Stack'i yatay yap (normal skor görünümü)
            scoreStackView.axis = .horizontal
            scoreStackView.spacing = 8
            
            // Skor label'larını göster
            homeScoreLabel.isHidden = false
            awayScoreLabel.isHidden = false
            scoreSeparatorLabel.isHidden = false
            
            // Scores
            homeScoreLabel.text = String(presentation.homePlayerScore)
            homeScoreLabel.font = AppFont.semiBold(size: Constants.scoreFontSize)
            homeScoreLabel.textAlignment = .center
            awayScoreLabel.text = String(presentation.awayPlayerScore)
            awayScoreLabel.font = AppFont.semiBold(size: Constants.scoreFontSize)
            awayScoreLabel.textAlignment = .center
            
            // Highlight winning score
            updateScoreColors(homeScore: presentation.homePlayerScore, awayScore: presentation.awayPlayerScore)
            
            // Status
            matchStatusLabel.text = presentation.matchStatus
            matchStatusLabel.textColor = .secondaryLabel
            matchStatusLabel.font = AppFont.regular(size: Constants.statusFontSize)
        }
    }
    
    // MARK: - Helpers
    
    /// Oyuncu adını formatlar
    /// Çinli oyuncular: "**Ding** Junhui" (soyisim bold, önce)
    /// Diğer oyuncular: "Judd **Trump**" (soyisim bold, sonda)
    private func createPlayerNameAttributedString(firstName: String, surname: String, flagEmoji: String?) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        let regularAttributes: [NSAttributedString.Key: Any] = [
            .font: AppFont.regular(size: Constants.playerFontSize),
            .foregroundColor: UIColor.label
        ]
        
        let boldAttributes: [NSAttributedString.Key: Any] = [
            .font: AppFont.bold(size: Constants.playerFontSize),
            .foregroundColor: UIColor.label
        ]
        
        let isChinese = PlayerNameHelper.isChinesePlayer(flagEmoji: flagEmoji)
        
        if isChinese {
            // Çinli oyuncu: Soyisim bold ve önce, isim regular ve sonda
            // "**Ding** Junhui"
            attributedString.append(NSAttributedString(string: surname + " ", attributes: boldAttributes))
            attributedString.append(NSAttributedString(string: firstName, attributes: regularAttributes))
        } else {
            // Diğer oyuncular: İsim regular ve önce, soyisim bold ve sonda
            // "Judd **Trump**"
            attributedString.append(NSAttributedString(string: firstName + " ", attributes: regularAttributes))
            attributedString.append(NSAttributedString(string: surname, attributes: boldAttributes))
        }
        
        return attributedString
    }
    
    private func updateScoreColors(homeScore: Int, awayScore: Int) {
        let winningColor = UIColor.systemGreen
        let losingColor = UIColor.secondaryLabel
        
        if homeScore > awayScore {
            homeScoreLabel.textColor = winningColor
            awayScoreLabel.textColor = losingColor
        } else if awayScore > homeScore {
            homeScoreLabel.textColor = losingColor
            awayScoreLabel.textColor = winningColor
        } else {
            homeScoreLabel.textColor = winningColor
            awayScoreLabel.textColor = winningColor
        }
    }
    
    // MARK: - Live Animation
    
    func startLiveAnimation() {
        liveContainerView.isHidden = false
        liveIndicatorView.layer.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.2
        animation.duration = 0.4
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        liveIndicatorView.layer.add(animation, forKey: "pulseAnimation")
    }
    
    func stopLiveAnimation() {
        liveIndicatorView.layer.removeAllAnimations()
        liveContainerView.isHidden = true
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopLiveAnimation()
        homePlayerImageView.configure(with: nil)
        awayPlayerImageView.configure(with: nil)
        homePlayerNameLabel.text = nil
        awayPlayerNameLabel.text = nil
        homePlayerFlagLabel.text = nil
        homePlayerFlagLabel.isHidden = true
        awayPlayerFlagLabel.text = nil
        awayPlayerFlagLabel.isHidden = true
        homePlayerRankLabel.text = nil
        homePlayerRankLabel.isHidden = true
        awayPlayerRankLabel.text = nil
        awayPlayerRankLabel.isHidden = true
        homeScoreLabel.text = nil
        homeScoreLabel.isHidden = false
        awayScoreLabel.text = nil
        awayScoreLabel.isHidden = false
        scoreSeparatorLabel.isHidden = false
        matchStatusLabel.text = nil
        matchStatusLabel.font = AppFont.regular(size: Constants.statusFontSize)
        onHomePlayerTapped = nil
        onAwayPlayerTapped = nil
        onScoreTapped = nil
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct LiveScoreCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Single Cell Preview - Live
            LiveScoreCellPreviewWrapper(presentation: .preview)
                .frame(height: 150)
                .previewDisplayName("Live Match")
            
            // Scheduled - Farklı gün (tarih + saat)
            LiveScoreCellPreviewWrapper(presentation: .previewScheduled)
                .frame(height: 150)
                .previewDisplayName("Scheduled - Different Day")
            
            // Scheduled - Bugün (sadece saat)
            LiveScoreCellPreviewWrapper(presentation: .previewScheduledToday)
                .frame(height: 150)
                .previewDisplayName("Scheduled - Today")
            
            // Multiple Cells in List
            LiveScoreCellListPreviewWrapper()
                .previewDisplayName("Cell List")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct LiveScoreCellPreviewWrapper: UIViewRepresentable {
    var presentation: LiveScoreCellPresentation = .preview
    
    func makeUIView(context: Context) -> UICollectionViewCell {
        let cell = LiveScoreCell(frame: CGRect(x: 0, y: 0, width: 375, height: 150))
        cell.configure(with: presentation)
        return cell
    }
    
    func updateUIView(_ uiView: UICollectionViewCell, context: Context) {}
}

@available(iOS 13.0, *)
private struct LiveScoreCellListPreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = LiveScorePreviewCollectionViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class LiveScorePreviewCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private let presentations = LiveScoreCellPresentation.previewList
    private var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(LiveScoreCell.self, forCellWithReuseIdentifier: LiveScoreCell.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        title = "Live Scores"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return presentations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LiveScoreCell.identifier, for: indexPath) as? LiveScoreCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: presentations[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 150)
    }
}

#endif
