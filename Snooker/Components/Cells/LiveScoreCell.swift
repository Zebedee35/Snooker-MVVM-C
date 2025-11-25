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
    let awayPlayerName: String
    let awayPlayerSurname: String
    let awayPlayerPhotoUrl: String?
    let awayPlayerScore: Int
    let matchStatus: String
    let round: String
    
    init(match: MatchDTO) {
        self.homePlayerName = match.homePlayer.firstName
        self.homePlayerSurname = match.homePlayer.surname
        self.homePlayerPhotoUrl = match.homePlayer.photoUrl
        self.homePlayerScore = match.homePlayerScore ?? 0
        self.awayPlayerName = match.awayPlayer.firstName
        self.awayPlayerSurname = match.awayPlayer.surname
        self.awayPlayerPhotoUrl = match.awayPlayer.photoUrl
        self.awayPlayerScore = match.awayPlayerScore ?? 0
        self.matchStatus = match.status
        self.round = match.round
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
    private let homePlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
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
        let stack = UIStackView(arrangedSubviews: [homePlayerImageView, homePlayerNameLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Constants.playerStackSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Away Player Views
    private let awayPlayerImageView = PlayerImageView(size: Constants.playerImageSize)
    
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
        let stack = UIStackView(arrangedSubviews: [awayPlayerImageView, awayPlayerNameLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Constants.playerStackSpacing
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
    }
    
    private func setupConstraints() {
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
        
        // Away Player
        awayPlayerImageView.configure(with: presentation.awayPlayerPhotoUrl)
        awayPlayerNameLabel.attributedText = createPlayerNameAttributedString(
            firstName: presentation.awayPlayerName,
            surname: presentation.awayPlayerSurname
        )
        
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
