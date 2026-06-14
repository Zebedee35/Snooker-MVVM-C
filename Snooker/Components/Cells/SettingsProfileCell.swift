//
//  SettingsProfileCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 14.06.2026.
//

import UIKit

/// Displays the signed-in user's avatar (initials), name and email.
final class SettingsProfileCell: UITableViewCell {

    static let reuseIdentifier = "SettingsProfileCell"

    private let avatarView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 22
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let initialsLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: 18)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emailLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.addSubview(avatarView)
        avatarView.addSubview(initialsLabel)
        contentView.addSubview(nameLabel)
        contentView.addSubview(emailLabel)

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            initialsLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),

            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 2),

            emailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            emailLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(with item: SettingsItem) {
        nameLabel.text = item.title
        emailLabel.text = item.subtitle
        emailLabel.isHidden = (item.subtitle?.isEmpty ?? true)
        initialsLabel.text = Self.initials(from: item.title, fallback: item.subtitle)
    }

    /// Derives up to two uppercase initials from the name, falling back to the
    /// first letter of the email when no name is available.
    private static func initials(from name: String, fallback email: String?) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let words = trimmed.split(separator: " ")
        if let first = words.first?.first {
            if words.count > 1, let last = words.last?.first {
                return "\(first)\(last)".uppercased()
            }
            return String(first).uppercased()
        }
        if let emailFirst = email?.first {
            return String(emailFirst).uppercased()
        }
        return "?"
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        emailLabel.text = nil
        initialsLabel.text = nil
    }
}
