//
//  LanguagePickerViewController.swift
//  Snooker
//
//  Lets the user override the app's language without leaving the app.
//
//  The list is built from whatever translations the bundle actually carries,
//  so adding a language to Localizable.xcstrings makes it appear here on the
//  next build with no change to this file.
//

import UIKit

final class LanguagePickerViewController: UIViewController {

    private enum Constants {
        static let estimatedRowHeight: CGFloat = 60
        static let cellIdentifier = "LanguageCell"
    }

    /// `nil` stands for the "System" row, which sits above the explicit
    /// languages and defers to the device setting.
    private let languages: [AppLanguage?] = [nil] + LanguageManager.shared.availableLanguages

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.dataSource = self
        table.delegate = self
        // Self-sizing: a fixed height clips the second line, and how tall a
        // row needs to be depends on the language name and the reader's
        // Dynamic Type setting.
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = Constants.estimatedRowHeight
        table.register(UITableViewCell.self, forCellReuseIdentifier: Constants.cellIdentifier)
        return table
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = L10n.Language.title
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Selection State

    private func isSelected(_ language: AppLanguage?) -> Bool {
        switch LanguageManager.shared.selection {
        case .system:
            return language == nil
        case .explicit(let code):
            return language?.code == code
        }
    }
}

// MARK: - UITableViewDataSource

extension LanguagePickerViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath)
        let language = languages[indexPath.row]

        var content = cell.defaultContentConfiguration()
        if let language {
            // Primary label is the language's own name, because that is what a
            // speaker of it scans for. The secondary label names it in the
            // current language, so someone who picked the wrong one by mistake
            // can still find their way back.
            content.text = language.endonym
            let exonym = language.exonym
            content.secondaryText = exonym.caseInsensitiveCompare(language.endonym) == .orderedSame ? nil : exonym
        } else {
            content.text = L10n.Language.system
            content.secondaryText = L10n.Language.systemResolvesTo(
                AppLanguage(code: LanguageManager.shared.resolvedCode).endonym
            )
        }
        content.textProperties.font = AppFont.medium(size: 16)
        content.secondaryTextProperties.font = AppFont.regular(size: 13)
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content

        cell.accessoryType = isSelected(language) ? .checkmark : .none
        cell.backgroundColor = .secondarySystemGroupedBackground
        return cell
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        "\(L10n.Language.relaunchNote)\n\n\(L10n.Language.helpTranslate)"
    }
}

// MARK: - UITableViewDelegate

extension LanguagePickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let language = languages[indexPath.row]
        guard !isSelected(language) else { return }

        // Changing the selection posts .appLanguageChanged, which rebuilds the
        // whole UI from the root — including this screen. No need to reload
        // the table here; it is about to be replaced.
        let selection: LanguageSelection = language.map { .explicit($0.code) } ?? .system
        LanguageManager.shared.setSelection(selection)

        // Keep the signed-in account's copy in step. The manager reads the
        // other preferences itself, so this screen doesn't need to know their
        // storage keys.
        AuthManager.shared.syncCurrentSettingsToCloud()
    }
}
