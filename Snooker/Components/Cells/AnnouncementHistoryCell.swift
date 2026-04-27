//
//  AnnouncementHistoryCell.swift
//  Snooker
//

import UIKit

final class AnnouncementHistoryCell: UITableViewCell {

    static let reuseIdentifier = "AnnouncementHistoryCell"

    private enum Constants {
        static let accentWidth: CGFloat = 4
        static let iconSize: CGFloat = 20
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let spacing: CGFloat = 10
    }

    // MARK: - UI

    private let accentBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = Constants.accentWidth / 2
        return view
    }()

    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.translatesAutoresizingMaskIntoConstraints = false
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppFont.bold(size: 13)
        label.textColor = .label
        return label
    }()

    private let contentBodyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppFont.regular(size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppFont.regular(size: 11)
        label.textColor = .tertiaryLabel
        return label
    }()

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [typeLabel, contentBodyLabel, dateLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .fill
        return stack
    }()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configure

    func configure(with record: DismissedAnnouncementRecord) {
        let visualStyle = AnnouncementHistoryCell.visualStyle(for: record.announcementType)
        accentBar.backgroundColor = visualStyle.tintColor
        iconImageView.image = UIImage(systemName: visualStyle.iconName)
        iconImageView.tintColor = visualStyle.tintColor
        typeLabel.text = visualStyle.title
        contentBodyLabel.text = record.content
        dateLabel.text = Self.dateFormatter.string(from: record.dismissedAt)
    }

    // MARK: - Setup

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(accentBar)
        contentView.addSubview(iconImageView)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            accentBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            accentBar.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalPadding),
            accentBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalPadding),
            accentBar.widthAnchor.constraint(equalToConstant: Constants.accentWidth),

            iconImageView.leadingAnchor.constraint(equalTo: accentBar.trailingAnchor, constant: Constants.spacing),
            iconImageView.topAnchor.constraint(equalTo: accentBar.topAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Constants.iconSize),

            textStack.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: Constants.spacing),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalPadding),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalPadding)
        ])
    }

    // MARK: - Visual Style

    private struct VisualStyle {
        let title: String
        let iconName: String
        let tintColor: UIColor
    }

    private static func visualStyle(for type: AnnouncementType) -> VisualStyle {
        switch type {
        case .error:
            return VisualStyle(title: "Error", iconName: "exclamationmark.octagon.fill", tintColor: .systemRed)
        case .warning:
            return VisualStyle(title: "Warning", iconName: "exclamationmark.triangle.fill", tintColor: .systemOrange)
        case .info:
            return VisualStyle(title: "Info", iconName: "info.circle.fill", tintColor: .systemBlue)
        case .success:
            return VisualStyle(title: "Success", iconName: "checkmark.circle.fill", tintColor: .systemGreen)
        }
    }
}
