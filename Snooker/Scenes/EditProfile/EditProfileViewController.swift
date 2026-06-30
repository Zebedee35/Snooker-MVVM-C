//
//  EditProfileViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 30.06.2026.
//

import UIKit

/// Lets a signed-in user edit their display name and pick a unique nickname.
///
/// Apple only hands over the user's name on the very first authorization, so a
/// reinstall can leave the name blank — this screen is the manual fallback.
/// The nickname is reserved here for an upcoming chat feature; uniqueness is
/// enforced by a DB unique index and reported back via `AuthError.nicknameTaken`.
final class EditProfileViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let nicknameMinLength = 3
        static let nicknameMaxLength = 20
    }

    // MARK: - UI

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.keyboardDismissMode = .interactive
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let nameField = EditProfileViewController.makeTextField(placeholder: "Your name")

    private lazy var nicknameField: UITextField = {
        let field = Self.makeTextField(placeholder: "nickname")
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.returnKeyType = .done
        return field
    }()

    private let nicknameHintLabel: UILabel = {
        let label = UILabel()
        label.text = "3–20 characters. Letters, numbers and underscore only. Used to find you in chat."
        label.font = AppFont.regular(size: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var saveButton: UIBarButtonItem = {
        UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(handleSave))
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.hidesWhenStopped = true
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        prefill()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameField.becomeFirstResponder()
    }

    // MARK: - Setup

    private func setupUI() {
        title = "Edit Profile"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = saveButton

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        contentStack.addArrangedSubview(makeSectionLabel("NAME"))
        contentStack.addArrangedSubview(makeFieldContainer(nameField))
        contentStack.setCustomSpacing(24, after: contentStack.arrangedSubviews.last!)

        contentStack.addArrangedSubview(makeSectionLabel("NICKNAME"))
        contentStack.addArrangedSubview(makeFieldContainer(nicknameField))
        contentStack.addArrangedSubview(nicknameHintLabel)

        nameField.delegate = self
        nicknameField.delegate = self

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    private func prefill() {
        nameField.text = AuthManager.shared.displayName
        nicknameField.text = AuthManager.shared.nickname
    }

    // MARK: - Actions

    @objc private func handleSave() {
        view.endEditing(true)

        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let nick = nicknameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Validate the nickname only when the user actually entered one — it is
        // optional, but if present it must obey the format rules.
        if !nick.isEmpty, let validationError = validateNickname(nick) {
            presentAlert(title: "Invalid Nickname", message: validationError)
            return
        }

        setLoading(true)
        Task { @MainActor in
            do {
                try await AuthManager.shared.updateProfile(displayName: name, nickname: nick)
                setLoading(false)
                navigationController?.popViewController(animated: true)
            } catch {
                setLoading(false)
                let message = (error as? AuthError)?.errorDescription
                    ?? "Could not save your profile. Please try again."
                presentAlert(title: "Error", message: message)
            }
        }
    }

    /// Returns a user-facing reason the nickname is invalid, or `nil` if valid.
    private func validateNickname(_ nickname: String) -> String? {
        guard nickname.count >= Constants.nicknameMinLength,
              nickname.count <= Constants.nicknameMaxLength else {
            return "Nickname must be \(Constants.nicknameMinLength)–\(Constants.nicknameMaxLength) characters long."
        }
        let allowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        guard nickname.unicodeScalars.allSatisfy({ allowed.contains($0) }) else {
            return "Nickname can only contain letters, numbers and underscore."
        }
        return nil
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
            navigationItem.rightBarButtonItem = saveButton
        }
        view.isUserInteractionEnabled = !isLoading
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Builders

    private static func makeTextField(placeholder: String) -> UITextField {
        let field = UITextField()
        field.placeholder = placeholder
        field.font = AppFont.regular(size: 16)
        field.textColor = .label
        field.borderStyle = .none
        field.clearButtonMode = .whileEditing
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }

    private func makeFieldContainer(_ field: UITextField) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(field)
        NSLayoutConstraint.activate([
            field.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            field.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12),
            field.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            field.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14)
        ])
        return container
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = AppFont.regular(size: 13)
        label.textColor = .secondaryLabel
        return label
    }
}

// MARK: - UITextFieldDelegate

extension EditProfileViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == nameField {
            nicknameField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            handleSave()
        }
        return true
    }
}
