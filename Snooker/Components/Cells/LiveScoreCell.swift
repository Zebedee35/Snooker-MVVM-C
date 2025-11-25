//
//  LiveScoreCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 25.11.2025.
//

import UIKit

// MARK: - LiveScoreCellPresentation

struct LiveScoreCellPresentation {
    let homePlayerName: String
    let homePlayerSurname: String
    let homePlayerPhotoUrl: String?
    let homePlayerScore: Int
    let homePlayerCountryCode: String?
    let homePlayerRank: Int?
    let awayPlayerName: String
    let awayPlayerSurname: String
    let awayPlayerPhotoUrl: String?
    let awayPlayerScore: Int
    let awayPlayerCountryCode: String?
    let awayPlayerRank: Int?
    let matchStatus: String
    let round: String
    
    init(match: MatchDTO) {
        self.homePlayerName = match.homePlayer.firstName
        self.homePlayerSurname = match.homePlayer.surname
        self.homePlayerPhotoUrl = match.homePlayer.photoUrl
        self.homePlayerScore = match.homePlayerScore ?? 0
        self.homePlayerCountryCode = match.homePlayer.countryCode
        self.homePlayerRank = match.homePlayer.rank
        self.awayPlayerName = match.awayPlayer.firstName
        self.awayPlayerSurname = match.awayPlayer.surname
        self.awayPlayerPhotoUrl = match.awayPlayer.photoUrl
        self.awayPlayerScore = match.awayPlayerScore ?? 0
        self.awayPlayerCountryCode = match.awayPlayer.countryCode
        self.awayPlayerRank = match.awayPlayer.rank
        self.matchStatus = match.status
        self.round = match.round
    }
    
    // Bayrak emoji helper
    func flagEmoji(for countryCode: String?) -> String? {
        guard var code = countryCode?.uppercased() else {
            return nil
        }
        
        // Handle sub-region codes (e.g., GB-WLS, GB-SCT, GB-NIR, GB-ENG)
        if code.contains("-") {
            let parts = code.split(separator: "-")
            if parts.count == 2 {
                let subRegion = String(parts[1])
                switch subRegion {
                case "WLS": return "🏴󠁧󠁢󠁷󠁬󠁳󠁿" // Wales
                case "SCT": return "🏴󠁧󠁢󠁳󠁣󠁴󠁿" // Scotland
                case "ENG": return "🏴󠁧󠁢󠁥󠁮󠁧󠁿" // England
                case "NIR": return "🇬🇧" // Northern Ireland (use GB flag)
                default: code = String(parts[0]) // Use main country code
                }
            }
        }
        
        // Standard 2-letter ISO country code
        guard code.count == 2 else {
            return nil
        }
        let base: UInt32 = 127397
        var emoji = ""
        for scalar in code.unicodeScalars {
            if let scalarValue = UnicodeScalar(base + scalar.value) {
                emoji.append(String(scalarValue))
            }
        }
        return emoji.isEmpty ? nil : emoji
    }
}

// MARK: - LiveScoreCell

final class LiveScoreCell: UITableViewCell {
    
    static let identifier = "LiveScoreCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let frameHeight: CGFloat = 120
        static let playerImageSize: PlayerImageSize = .medium
        static let playerFontSize: CGFloat = 13
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
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let homePlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    private let homePlayerFlagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.flagFontSize)
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homePlayerRankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.rankFontSize, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let homePlayerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.playerFontSize)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var homePlayerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [homePlayerImageContainerView, homePlayerRankLabel, homePlayerNameLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Away Player Views
    private let awayPlayerImageContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let awayPlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
    private let awayPlayerFlagLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.flagFontSize)
        label.textAlignment = .center
        label.backgroundColor = .systemBackground
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayPlayerRankLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.rankFontSize, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayPlayerNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.playerFontSize)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var awayPlayerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [awayPlayerImageContainerView, awayPlayerRankLabel, awayPlayerNameLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Score Views
    private let homeScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.scoreFontSize, weight: .semibold)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let scoreSeparatorLabel: UILabel = {
        let label = UILabel()
        label.text = "-"
        label.font = .systemFont(ofSize: Constants.scoreFontSize, weight: .regular)
        label.textColor = .systemGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let awayScoreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.scoreFontSize, weight: .semibold)
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
        label.font = .systemFont(ofSize: Constants.statusFontSize)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var centerStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [scoreStackView, matchStatusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var mainStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [homePlayerStackView, centerStackView, awayPlayerStackView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
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
        containerView.addSubview(mainStackView)
        
        // Home player image container setup
        homePlayerImageContainerView.addSubview(homePlayerImageView)
        homePlayerImageContainerView.addSubview(homePlayerFlagLabel)
        
        // Away player image container setup
        awayPlayerImageContainerView.addSubview(awayPlayerImageView)
        awayPlayerImageContainerView.addSubview(awayPlayerFlagLabel)
    }
    
    private func setupConstraints() {
        let imageSize = Constants.playerImageSize.dimension
        
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            // Main Stack
            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.verticalPadding),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.verticalPadding),
            
            // Player Stacks width
            homePlayerStackView.widthAnchor.constraint(equalToConstant: 100),
            awayPlayerStackView.widthAnchor.constraint(equalToConstant: 100),
            
            // Home Player Image Container
            homePlayerImageContainerView.widthAnchor.constraint(equalToConstant: imageSize),
            homePlayerImageContainerView.heightAnchor.constraint(equalToConstant: imageSize),
            
            homePlayerImageView.topAnchor.constraint(equalTo: homePlayerImageContainerView.topAnchor),
            homePlayerImageView.leadingAnchor.constraint(equalTo: homePlayerImageContainerView.leadingAnchor),
            homePlayerImageView.trailingAnchor.constraint(equalTo: homePlayerImageContainerView.trailingAnchor),
            homePlayerImageView.bottomAnchor.constraint(equalTo: homePlayerImageContainerView.bottomAnchor),
            
            // Home Player Flag - bottom right corner, overlapping image
            homePlayerFlagLabel.trailingAnchor.constraint(equalTo: homePlayerImageContainerView.trailingAnchor, constant: 2),
            homePlayerFlagLabel.bottomAnchor.constraint(equalTo: homePlayerImageContainerView.bottomAnchor, constant: 2),
            homePlayerFlagLabel.widthAnchor.constraint(equalToConstant: 22),
            homePlayerFlagLabel.heightAnchor.constraint(equalToConstant: 22),
            
            // Away Player Image Container
            awayPlayerImageContainerView.widthAnchor.constraint(equalToConstant: imageSize),
            awayPlayerImageContainerView.heightAnchor.constraint(equalToConstant: imageSize),
            
            awayPlayerImageView.topAnchor.constraint(equalTo: awayPlayerImageContainerView.topAnchor),
            awayPlayerImageView.leadingAnchor.constraint(equalTo: awayPlayerImageContainerView.leadingAnchor),
            awayPlayerImageView.trailingAnchor.constraint(equalTo: awayPlayerImageContainerView.trailingAnchor),
            awayPlayerImageView.bottomAnchor.constraint(equalTo: awayPlayerImageContainerView.bottomAnchor),
            
            // Away Player Flag - bottom right corner, overlapping image
            awayPlayerFlagLabel.trailingAnchor.constraint(equalTo: awayPlayerImageContainerView.trailingAnchor, constant: 2),
            awayPlayerFlagLabel.bottomAnchor.constraint(equalTo: awayPlayerImageContainerView.bottomAnchor, constant: 2),
            awayPlayerFlagLabel.widthAnchor.constraint(equalToConstant: 22),
            awayPlayerFlagLabel.heightAnchor.constraint(equalToConstant: 22),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: LiveScoreCellPresentation) {
        // Home Player
        homePlayerImageView.configure(with: presentation.homePlayerPhotoUrl)
        homePlayerNameLabel.attributedText = createPlayerNameAttributedString(
            firstName: presentation.homePlayerName,
            surname: presentation.homePlayerSurname
        )
        
        // Home Player Flag
        if let flagEmoji = presentation.flagEmoji(for: presentation.homePlayerCountryCode) {
            homePlayerFlagLabel.text = flagEmoji
            homePlayerFlagLabel.isHidden = false
        } else {
            homePlayerFlagLabel.isHidden = true
        }
        
        // Home Player Rank
        if let rank = presentation.homePlayerRank {
            homePlayerRankLabel.text = "#\(rank)"
            homePlayerRankLabel.isHidden = false
        } else {
            homePlayerRankLabel.isHidden = true
        }
        
        // Away Player
        awayPlayerImageView.configure(with: presentation.awayPlayerPhotoUrl)
        awayPlayerNameLabel.attributedText = createPlayerNameAttributedString(
            firstName: presentation.awayPlayerName,
            surname: presentation.awayPlayerSurname
        )
        
        // Away Player Flag
        if let flagEmoji = presentation.flagEmoji(for: presentation.awayPlayerCountryCode) {
            awayPlayerFlagLabel.text = flagEmoji
            awayPlayerFlagLabel.isHidden = false
        } else {
            awayPlayerFlagLabel.isHidden = true
        }
        
        // Away Player Rank
        if let rank = presentation.awayPlayerRank {
            awayPlayerRankLabel.text = "#\(rank)"
            awayPlayerRankLabel.isHidden = false
        } else {
            awayPlayerRankLabel.isHidden = true
        }
        
        // Scores
        homeScoreLabel.text = String(presentation.homePlayerScore)
        awayScoreLabel.text = String(presentation.awayPlayerScore)
        
        // Highlight winning score
        updateScoreColors(homeScore: presentation.homePlayerScore, awayScore: presentation.awayPlayerScore)
        
        // Status
        matchStatusLabel.text = presentation.matchStatus
    }
    
    func configure(with match: MatchDTO) {
        let presentation = LiveScoreCellPresentation(match: match)
        configure(with: presentation)
    }
    
    // MARK: - Helpers
    
    private func createPlayerNameAttributedString(firstName: String, surname: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        let firstNameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: Constants.playerFontSize),
            .foregroundColor: UIColor.label
        ]
        
        let surnameAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: Constants.playerFontSize),
            .foregroundColor: UIColor.label
        ]
        
        attributedString.append(NSAttributedString(string: firstName + "\n", attributes: firstNameAttributes))
        attributedString.append(NSAttributedString(string: surname, attributes: surnameAttributes))
        
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
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
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
        awayScoreLabel.text = nil
        matchStatusLabel.text = nil
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct LiveScoreCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Single Cell Preview
            LiveScoreCellPreviewWrapper()
                .frame(height: 150)
                .previewDisplayName("Single Cell - Light")
            
            LiveScoreCellPreviewWrapper()
                .frame(height: 150)
                .preferredColorScheme(.dark)
                .previewDisplayName("Single Cell - Dark")
            
            // Multiple Cells in List
            LiveScoreCellListPreviewWrapper()
                .previewDisplayName("Cell List")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct LiveScoreCellPreviewWrapper: UIViewRepresentable {
    func makeUIView(context: Context) -> UITableViewCell {
        let cell = LiveScoreCell(style: .default, reuseIdentifier: LiveScoreCell.identifier)
        cell.configure(with: TournamentWithMatchesDTO.preview)
        return cell
    }
    
    func updateUIView(_ uiView: UITableViewCell, context: Context) {}
}

@available(iOS 13.0, *)
private struct LiveScoreCellListPreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UITableViewController {
        let controller = LiveScorePreviewTableViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UITableViewController, context: Context) {}
}

private class LiveScorePreviewTableViewController: UITableViewController {
    private let matches = TournamentWithMatchesDTO.previewList.matches
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(LiveScoreCell.self, forCellReuseIdentifier: LiveScoreCell.identifier)
        tableView.backgroundColor = .systemBackground
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        title = "Live Scores"
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LiveScoreCell.identifier, for: indexPath) as? LiveScoreCell else {
            return UITableViewCell()
        }
        cell.configure(with: matches[indexPath.row])
        return cell
    }
}

#endif
