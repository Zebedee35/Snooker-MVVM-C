//
//  MatchDetailViewController.swift
//  Snooker
//
//  Per-match detail: a frame-by-frame breakdown (points + 50+ breaks) under a
//  player/score header, WST-style. The winner's points in each frame are
//  highlighted. A "Head-to-Head" button preserves the old tap destination.
//
//  Frames use a UITableView so long matches (Masters finals run to 35 frames)
//  scroll smoothly with cell reuse.
//

import UIKit

final class MatchDetailViewController: UIViewController {

    // MARK: - Public

    /// Invoked when the user taps the Head-to-Head button.
    var onHeadToHeadTapped: (() -> Void)?
    /// Invoked when the user taps a player's photo or name.
    var onHomePlayerTapped: (() -> Void)?
    var onAwayPlayerTapped: (() -> Void)?

    // MARK: - Data

    private let presentation: MatchDetailPresentation
    /// Frames shown in the table. Seeded from the presentation, then lazily
    /// filled from the network when the source screen didn't provide them
    /// (e.g. the tournament list, whose RPC omits frames).
    private var frames: [MatchDetailFrame]
    private weak var statusLabel: UILabel?

    // MARK: - UI

    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.separatorStyle = .none
        table.rowHeight = 44
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(FrameRowCell.self, forCellReuseIdentifier: FrameRowCell.reuseID)
        return table
    }()

    /// Cached so we only re-measure its height when the width actually changes.
    private var headerView: UIView?
    private var lastHeaderWidth: CGFloat = 0

    // MARK: - Init

    init(presentation: MatchDetailPresentation) {
        self.presentation = presentation
        self.frames = presentation.frames
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = presentation.round

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "person.2.fill"),
            style: .plain,
            target: self,
            action: #selector(headToHeadTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let header = buildHeaderView()
        headerView = header
        tableView.tableHeaderView = header

        updateEmptyState()
        loadFramesIfNeeded()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if presentation.isLive { startLivePulse() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeHeaderToFit()
    }

    // MARK: - Lazy frame loading

    /// Fetches the frame breakdown when the source screen didn't include it
    /// (tournament list). Skips the request when we already have frames.
    private func loadFramesIfNeeded() {
        guard frames.isEmpty, !presentation.matchId.isEmpty else { return }
        Task { @MainActor in
            do {
                let dtos = try await SupabaseAPI.fetchMatchFrames(matchId: presentation.matchId)
                self.frames = dtos.map(MatchDetailFrame.init(dto:))
                self.updateEmptyState()
                self.tableView.reloadData()
            } catch {
                print("[MatchDetail] Failed to load frames: \(error)")
            }
        }
    }

    /// Shows the "no frames yet" footer only while the table is empty.
    private func updateEmptyState() {
        tableView.tableFooterView = frames.isEmpty ? buildEmptyFramesView() : nil
    }

    // MARK: - LIVE pulse

    /// Gentle scale pulse on the status pill while the match is live — same
    /// feel as the bracket button's "NEW" badge.
    private func startLivePulse() {
        guard let label = statusLabel, label.layer.animation(forKey: "livePulse") == nil else { return }
        let pulse = CABasicAnimation(keyPath: "transform.scale")
        pulse.fromValue = 1.0
        pulse.toValue = 1.12
        pulse.duration = 0.7
        pulse.autoreverses = true
        pulse.repeatCount = .infinity
        pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        label.layer.add(pulse, forKey: "livePulse")
    }

    /// Auto Layout sizing for `tableHeaderView` (UIKit doesn't do it for us).
    private func sizeHeaderToFit() {
        guard let header = headerView else { return }
        let width = tableView.bounds.width
        guard width > 0, width != lastHeaderWidth else { return }
        lastHeaderWidth = width

        let target = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let height = header.systemLayoutSizeFitting(
            target,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

        if header.frame.height != height {
            header.frame.size = CGSize(width: width, height: height)
            tableView.tableHeaderView = header
        }
    }

    // MARK: - Header

    private func buildHeaderView() -> UIView {
        let stack = UIStackView(arrangedSubviews: [
            makeMetaLabel(),
            makeStatusLabel(),
            makePlayersRow(),
            makeHeadToHeadButton()
        ])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 12, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        return container
    }

    private func makeMetaLabel() -> UILabel {
        let label = UILabel()
        label.font = AppFont.regular(size: 13)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        var parts: [String] = []
        if let date = Self.formattedDate(presentation.startDateTime) { parts.append(date) }
        if let name = presentation.tournamentName, !name.isEmpty { parts.append(name) }
        label.text = parts.joined(separator: "\n")
        return label
    }

    private func makeStatusLabel() -> UIView {
        let label = PaddedLabel(insets: UIEdgeInsets(top: 5, left: 12, bottom: 5, right: 12))
        label.font = AppFont.bold(size: 13)
        label.textAlignment = .center
        label.attributedText = NSAttributedString(
            string: presentation.statusText,
            attributes: [.kern: 2.0]
        )

        if presentation.isLive {
            label.textColor = .white
            label.backgroundColor = .systemRed
            label.layer.cornerRadius = 12
            label.layer.masksToBounds = true
        } else {
            label.textColor = .secondaryLabel
        }
        statusLabel = label

        // Center the pill rather than stretching it across the row.
        let container = UIView()
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        return container
    }

    private func makePlayersRow() -> UIView {
        let home = makePlayerColumn(
            photo: presentation.homePlayerPhotoUrl,
            first: presentation.homePlayerName,
            surname: presentation.homePlayerSurname,
            flag: presentation.homePlayerFlag
        )
        home.isUserInteractionEnabled = true
        home.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(homePlayerColumnTapped)))

        let away = makePlayerColumn(
            photo: presentation.awayPlayerPhotoUrl,
            first: presentation.awayPlayerName,
            surname: presentation.awayPlayerSurname,
            flag: presentation.awayPlayerFlag
        )
        away.isUserInteractionEnabled = true
        away.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(awayPlayerColumnTapped)))

        let score = makeScoreBlock()

        let row = UIStackView(arrangedSubviews: [home, score, away])
        row.axis = .horizontal
        row.alignment = .top
        row.distribution = .equalSpacing
        return row
    }

    private func makePlayerColumn(photo: String?, first: String, surname: String, flag: String?) -> UIView {
        let image = PlayerImageView(size: .large)
        image.configure(with: photo)

        let firstLabel = UILabel()
        firstLabel.font = AppFont.regular(size: 13)
        firstLabel.textColor = .secondaryLabel
        firstLabel.textAlignment = .center
        firstLabel.text = first

        let surnameLabel = UILabel()
        surnameLabel.font = AppFont.bold(size: 15)
        surnameLabel.textColor = .label
        surnameLabel.textAlignment = .center
        surnameLabel.numberOfLines = 2
        surnameLabel.text = surname

        let flagLabel = UILabel()
        flagLabel.font = AppFont.regular(size: 18)
        flagLabel.textAlignment = .center
        flagLabel.text = flag

        let stack = UIStackView(arrangedSubviews: [image, firstLabel, surnameLabel, flagLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        stack.widthAnchor.constraint(equalToConstant: 110).isActive = true
        return stack
    }

    private func makeScoreBlock() -> UIView {
        let caption = UILabel()
        caption.font = AppFont.regular(size: 12)
        caption.textColor = .secondaryLabel
        caption.textAlignment = .center
        caption.text = "Frames"

        let homeScore = UILabel()
        homeScore.font = AppFont.bold(size: 30)
        homeScore.textColor = presentation.homePlayerScore >= presentation.awayPlayerScore ? .label : .secondaryLabel
        homeScore.text = "\(presentation.homePlayerScore)"

        let total = UILabel()
        total.font = AppFont.regular(size: 13)
        total.textColor = .tertiaryLabel
        total.text = "(\(presentation.framesPlayed))"

        let awayScore = UILabel()
        awayScore.font = AppFont.bold(size: 30)
        awayScore.textColor = presentation.awayPlayerScore >= presentation.homePlayerScore ? .label : .secondaryLabel
        awayScore.text = "\(presentation.awayPlayerScore)"

        let scores = UIStackView(arrangedSubviews: [homeScore, total, awayScore])
        scores.axis = .horizontal
        scores.alignment = .center
        scores.spacing = 8

        let stack = UIStackView(arrangedSubviews: [caption, scores])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 4
        // Nudge the score block down so it centers against the player photos.
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 36, left: 0, bottom: 0, right: 0)
        return stack
    }

    private func makeHeadToHeadButton() -> UIView {
        var config = UIButton.Configuration.tinted()
        config.title = "Head-to-Head"
        config.image = UIImage(systemName: "person.2.fill")
        config.imagePadding = 8
        config.baseForegroundColor = .systemIndigo
        config.baseBackgroundColor = .systemIndigo
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.addTarget(self, action: #selector(headToHeadTapped), for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    private func buildEmptyFramesView() -> UIView {
        let label = UILabel()
        label.font = AppFont.regular(size: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Frame details will appear here once play begins."
        label.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 80))
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 24),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])
        return container
    }

    // MARK: - Actions

    @objc private func headToHeadTapped() {
        onHeadToHeadTapped?()
    }

    @objc private func homePlayerColumnTapped() {
        onHomePlayerTapped?()
    }

    @objc private func awayPlayerColumnTapped() {
        onAwayPlayerTapped?()
    }

    // MARK: - Helpers

    private static func formattedDate(_ iso: String?) -> String? {
        guard let iso else { return nil }
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = parser.date(from: iso)
        if date == nil {
            parser.formatOptions = [.withInternetDateTime]
            date = parser.date(from: iso)
        }
        guard let date else { return nil }
        let out = DateFormatter()
        out.locale = Locale.current
        out.dateFormat = "d MMM yyyy · HH:mm"
        return out.string(from: date)
    }
}

// MARK: - Table DataSource / Delegate

extension MatchDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        frames.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: FrameRowCell.reuseID, for: indexPath) as? FrameRowCell else {
            return UITableViewCell()
        }
        cell.configure(with: frames[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        frames.isEmpty ? nil : FrameColumnsView.header()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        frames.isEmpty ? 0 : 48
    }
}

// MARK: - Frame Columns (shared layout for header + rows)

/// Builds the 5-column layout shared by the column-title header and each row.
private enum FrameColumnsView {

    static func header() -> UIView {
        let container = UIView()
        container.backgroundColor = .systemBackground
        let row = makeRow(
            homeBreak: "Break\n50+", homePoints: "Points", frame: "Frame",
            awayPoints: "Points", awayBreak: "Break\n50+",
            isHeader: true, homeWon: false, awayWon: false
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(row)
        let divider = UIView()
        divider.backgroundColor = .separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(divider)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            divider.heightAnchor.constraint(equalToConstant: 0.5),
            divider.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    static func makeRow(
        homeBreak: String, homePoints: String, frame: String,
        awayPoints: String, awayBreak: String,
        isHeader: Bool, homeWon: Bool, awayWon: Bool
    ) -> UIStackView {
        let columns = [
            makeColumn(text: homeBreak, isHeader: isHeader, emphasized: false, won: false),
            makeColumn(text: homePoints, isHeader: isHeader, emphasized: true, won: homeWon),
            makeColumn(text: frame, isHeader: isHeader, emphasized: false, won: false),
            makeColumn(text: awayPoints, isHeader: isHeader, emphasized: true, won: awayWon),
            makeColumn(text: awayBreak, isHeader: isHeader, emphasized: false, won: false)
        ]
        let row = UIStackView(arrangedSubviews: columns)
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .fillEqually
        return row
    }

    private static func makeColumn(text: String, isHeader: Bool, emphasized: Bool, won: Bool) -> UIView {
        let label = PaddedLabel(insets: UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10))
        label.textAlignment = .center
        label.numberOfLines = isHeader ? 2 : 1
        label.translatesAutoresizingMaskIntoConstraints = false

        if isHeader {
            label.font = AppFont.semiBold(size: 13)
            label.textColor = .secondaryLabel
            label.text = text
        } else {
            label.font = won ? AppFont.bold(size: 16) : AppFont.regular(size: 16)
            label.text = text
            if won {
                label.textColor = .black
                label.backgroundColor = .systemYellow
                label.layer.cornerRadius = 8
                label.layer.masksToBounds = true
            } else {
                label.textColor = emphasized ? .label : .secondaryLabel
            }
        }

        let container = UIView()
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])
        return container
    }
}

// MARK: - Frame Row Cell

private final class FrameRowCell: UITableViewCell {
    static let reuseID = "FrameRowCell"

    private var rowStack: UIStackView?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with frame: MatchDetailFrame) {
        rowStack?.removeFromSuperview()
        let row = FrameColumnsView.makeRow(
            homeBreak: frame.homeBreak > 0 ? "\(frame.homeBreak)" : "-",
            homePoints: "\(frame.homePoints)",
            frame: "\(frame.frameNumber)",
            awayPoints: "\(frame.awayPoints)",
            awayBreak: frame.awayBreak > 0 ? "\(frame.awayBreak)" : "-",
            isHeader: false,
            homeWon: frame.homeWon,
            awayWon: frame.awayWon
        )
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: contentView.topAnchor),
            row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
        rowStack = row
    }
}

// MARK: - Padded Label

/// UILabel with content insets — used for the yellow winner pill.
private final class PaddedLabel: UILabel {
    private let insets: UIEdgeInsets

    init(insets: UIEdgeInsets) {
        self.insets = insets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + insets.left + insets.right,
            height: size.height + insets.top + insets.bottom
        )
    }
}
