//
//  BracketViewController.swift
//  Snooker
//
//  Apple Sports-style tournament bracket. Rounds become columns ordered by
//  fixture number; within each round, adjacent matches feed the next round
//  (2:1), while an equal-sized previous round is treated as a play-in (1:1).
//

import UIKit

final class BracketViewController: UIViewController {

    // MARK: - Data

    private let columns: [[BracketMatch]]

    // MARK: - Layout constants

    private let cardSize = BracketMatchCardView.cardSize
    private let hGap: CGFloat = 40
    private let vGap: CGFloat = 14
    private let topInset: CGFloat = 52   // room for round labels
    private let sideInset: CGFloat = 16
    private let bottomInset: CGFloat = 28

    private var columnPitch: CGFloat { cardSize.width + hGap }
    private var rowPitch: CGFloat { cardSize.height + vGap }

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let connectorLayer = CAShapeLayer()

    // MARK: - Init

    init(matches: [MatchDTO], title: String) {
        self.columns = BracketBuilder.buildColumns(from: matches)
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground

        setupScrollView()

        guard !columns.isEmpty else {
            showEmptyState()
            return
        }
        buildBracket()
    }

    // MARK: - Setup

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.showsVerticalScrollIndicator = true
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Bracket build

    private func buildBracket() {
        let centersY = computeCenterYs()

        // Connectors first so cards sit on top of the lines.
        connectorLayer.strokeColor = UIColor.tertiaryLabel.cgColor
        connectorLayer.fillColor = nil
        connectorLayer.lineWidth = 1.5
        connectorLayer.path = makeConnectorPath(centersY: centersY).cgPath
        contentView.layer.addSublayer(connectorLayer)

        var maxBottom: CGFloat = 0

        for (col, matches) in columns.enumerated() {
            let x = sideInset + CGFloat(col) * columnPitch

            // Round label above the column.
            let label = makeRoundLabel(text: matches.first?.round ?? "")
            label.frame = CGRect(x: x, y: 18, width: cardSize.width, height: 22)
            contentView.addSubview(label)

            for (row, match) in matches.enumerated() {
                let centerY = centersY[col][row]
                let card = BracketMatchCardView()
                card.configure(with: match)
                card.frame = CGRect(
                    x: x,
                    y: centerY - cardSize.height / 2,
                    width: cardSize.width,
                    height: cardSize.height
                )
                contentView.addSubview(card)
                maxBottom = max(maxBottom, centerY + cardSize.height / 2)
            }
        }

        let contentWidth = sideInset * 2 + CGFloat(columns.count) * columnPitch - hGap
        let contentHeight = maxBottom + bottomInset
        contentView.frame = CGRect(x: 0, y: 0, width: contentWidth, height: contentHeight)
        scrollView.contentSize = contentView.frame.size
    }

    /// Vertical center for every match, per column.
    private func computeCenterYs() -> [[CGFloat]] {
        var result: [[CGFloat]] = []

        for (col, matches) in columns.enumerated() {
            guard col > 0 else {
                // Leftmost column: evenly stacked.
                let ys = (0..<matches.count).map {
                    topInset + CGFloat($0) * rowPitch + cardSize.height / 2
                }
                result.append(ys)
                continue
            }

            let prev = result[col - 1]
            let prevCount = columns[col - 1].count
            let curCount = matches.count
            var ys: [CGFloat] = []

            if prevCount == 2 * curCount {
                // Standard knockout: two children → one parent.
                for i in 0..<curCount {
                    ys.append((prev[2 * i] + prev[2 * i + 1]) / 2)
                }
            } else if prevCount == curCount {
                // Play-in / byes: one child aligns with one parent.
                ys = prev
            } else {
                // Irregular relationship — e.g. a partial play-in/Wildcard round
                // (2 matches before a 16-match Round 1), or missing intermediate
                // rounds. Lay this column out on its OWN natural grid instead of
                // cramming it into the previous (smaller) column's span, which
                // would overlap the cards.
                ys = (0..<curCount).map {
                    topInset + CGFloat($0) * rowPitch + cardSize.height / 2
                }
            }
            result.append(ys)
        }
        return result
    }

    private func makeConnectorPath(centersY: [[CGFloat]]) -> UIBezierPath {
        let path = UIBezierPath()
        guard columns.count > 1 else { return path }

        for col in 1..<columns.count {
            let prevCount = columns[col - 1].count
            let curCount = columns[col].count
            let xPrevRight = sideInset + CGFloat(col - 1) * columnPitch + cardSize.width
            let xCurLeft = sideInset + CGFloat(col) * columnPitch
            let midX = (xPrevRight + xCurLeft) / 2

            func connect(childRow: Int, parentRow: Int) {
                let childY = centersY[col - 1][childRow]
                let parentY = centersY[col][parentRow]
                path.move(to: CGPoint(x: xPrevRight, y: childY))
                path.addLine(to: CGPoint(x: midX, y: childY))
                path.addLine(to: CGPoint(x: midX, y: parentY))
                path.addLine(to: CGPoint(x: xCurLeft, y: parentY))
            }

            if prevCount == 2 * curCount {
                for i in 0..<curCount {
                    connect(childRow: 2 * i, parentRow: i)
                    connect(childRow: 2 * i + 1, parentRow: i)
                }
            } else if prevCount == curCount {
                for i in 0..<curCount {
                    connect(childRow: i, parentRow: i)
                }
            }
            // Irregular columns: no connectors (ambiguous).
        }
        return path
    }

    // MARK: - Helpers

    private func makeRoundLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = AppFont.semiBold(size: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        return label
    }

    private func showEmptyState() {
        let label = UILabel()
        label.text = "Bracket data isn't available for this tournament."
        label.font = AppFont.medium(size: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            label.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
}
