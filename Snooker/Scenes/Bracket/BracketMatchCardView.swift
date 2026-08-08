//
//  BracketMatchCardView.swift
//  Snooker
//
//  A single match card in the bracket: home/away name + score, winner bolded.
//

import UIKit

final class BracketMatchCardView: UIView {

    static let cardSize = CGSize(width: 152, height: 60)

    private let homeNameLabel = UILabel()
    private let awayNameLabel = UILabel()
    private let homeScoreLabel = UILabel()
    private let awayScoreLabel = UILabel()
    private let dividerView = UIView()

    init() {
        super.init(frame: CGRect(origin: .zero, size: Self.cardSize))
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        backgroundColor = .secondarySystemGroupedBackground
        layer.cornerRadius = 10
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.separator.cgColor

        [homeNameLabel, awayNameLabel].forEach {
            $0.lineBreakMode = .byTruncatingTail
            $0.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        [homeScoreLabel, awayScoreLabel].forEach {
            $0.textAlignment = .right
            $0.setContentHuggingPriority(.required, for: .horizontal)
            $0.setContentCompressionResistancePriority(.required, for: .horizontal)
        }
        dividerView.backgroundColor = .separator

        let homeRow = UIStackView(arrangedSubviews: [homeNameLabel, homeScoreLabel])
        let awayRow = UIStackView(arrangedSubviews: [awayNameLabel, awayScoreLabel])
        [homeRow, awayRow].forEach {
            $0.axis = .horizontal
            $0.spacing = 6
            $0.alignment = .center
        }

        let vstack = UIStackView(arrangedSubviews: [homeRow, dividerView, awayRow])
        vstack.axis = .vertical
        vstack.spacing = 6
        vstack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(vstack)

        NSLayoutConstraint.activate([
            vstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            vstack.centerYAnchor.constraint(equalTo: centerYAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }

    func configure(with match: BracketMatch) {
        homeNameLabel.text = match.homeName
        awayNameLabel.text = match.awayName
        // Future (placeholder) rounds carry no scores.
        homeScoreLabel.text = match.isPlaceholder ? "" : (match.homeScore.map(String.init) ?? "–")
        awayScoreLabel.text = match.isPlaceholder ? "" : (match.awayScore.map(String.init) ?? "–")
        style(name: homeNameLabel, score: homeScoreLabel, isWinner: match.homeIsWinner, isTBD: match.homeName == "TBD")
        style(name: awayNameLabel, score: awayScoreLabel, isWinner: match.awayIsWinner, isTBD: match.awayName == "TBD")
    }

    private func style(name: UILabel, score: UILabel, isWinner: Bool, isTBD: Bool) {
        let font = isWinner ? AppFont.bold(size: 13) : AppFont.medium(size: 13)
        // Unknown slots stay faint; advanced players read as normal participants.
        let color: UIColor = isTBD ? .tertiaryLabel : (isWinner ? .label : .secondaryLabel)
        name.font = font
        name.textColor = color
        score.font = font
        score.textColor = isWinner ? .label : .secondaryLabel
    }
}
