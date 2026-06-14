//
//  SettingsAppleSignInCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 14.06.2026.
//

import UIKit
import AuthenticationServices

/// Hosts the system "Sign in with Apple" button inside a settings row.
final class SettingsAppleSignInCell: UITableViewCell {

    static let reuseIdentifier = "SettingsAppleSignInCell"

    /// Invoked when the user taps the Apple button.
    var onSignIn: (() -> Void)?

    private lazy var appleButton: ASAuthorizationAppleIDButton = {
        let style: ASAuthorizationAppleIDButton.Style =
            traitCollection.userInterfaceStyle == .dark ? .white : .black
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        button.cornerRadius = 10
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapApple), for: .touchUpInside)
        return button
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
        backgroundColor = .clear
        contentView.addSubview(appleButton)

        NSLayoutConstraint.activate([
            appleButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            appleButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            appleButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            appleButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    @objc private func didTapApple() {
        onSignIn?()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onSignIn = nil
    }
}
