//
//  SettingsViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

final class SettingsViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cellHeight: CGFloat = 50
        static let headerHeight: CGFloat = 44
        static let footerHeight: CGFloat = 80
    }
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        // Grouped background so cells (secondarySystemGroupedBackground) stand
        // out from the screen in BOTH light and dark — plain systemBackground
        // is white-on-white in light mode.
        tableView.backgroundColor = .systemGroupedBackground
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SettingsCell.self, forCellReuseIdentifier: SettingsCell.reuseIdentifier)
        tableView.register(SettingsToggleCell.self, forCellReuseIdentifier: SettingsToggleCell.reuseIdentifier)
        tableView.register(SettingsAppCell.self, forCellReuseIdentifier: SettingsAppCell.reuseIdentifier)
        tableView.register(SettingsAppleSignInCell.self, forCellReuseIdentifier: SettingsAppleSignInCell.reuseIdentifier)
        tableView.register(SettingsProfileCell.self, forCellReuseIdentifier: SettingsProfileCell.reuseIdentifier)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    // MARK: - Properties
    
    private let viewModel: SettingsViewModelProtocol
    weak var coordinator: SettingsCoordinator?
    
    // MARK: - Init
    
    init(viewModel: SettingsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // navigationItem.title, not title: setting `title` on a tab's root
        // view controller also writes through to its tabBarItem, which would
        // overwrite the short tab label the moment this view loads.
        navigationItem.title = L10n.Settings.title
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(tableView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        viewModel.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].items.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Uppercased here rather than in the catalog so translators write
        // natural case, and so locale rules (Turkish dotless i) are respected.
        viewModel.sections[section].title.uppercased(with: LanguageManager.shared.locale)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        
        switch item.type {
        case .navigation, .action, .radio:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingsCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
            
        case .toggle:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingsToggleCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsToggleCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            cell.onToggle = { [weak self] isOn in
                self?.viewModel.handleToggle(item: item, isOn: isOn)
            }
            return cell
            
        case .app:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingsAppCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsAppCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell

        case .appleSignIn:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingsAppleSignInCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsAppleSignInCell else {
                return UITableViewCell()
            }
            cell.onSignIn = { [weak self] in
                self?.viewModel.handleSelection(item: item)
            }
            return cell

        case .profile:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: SettingsProfileCell.reuseIdentifier,
                for: indexPath
            ) as? SettingsProfileCell else {
                return UITableViewCell()
            }
            cell.configure(with: item)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        // Show footer only for the last section (About Us)
        guard section == viewModel.sections.count - 1 else { return nil }
        
        let footerView = UIView()
        
        let byLabel = UILabel()
        byLabel.text = L10n.Settings.byAuthor("Tayfun Susamcioglu")
        byLabel.font = AppFont.regular(size: 12)
        byLabel.textColor = .tertiaryLabel
        byLabel.textAlignment = .center
        byLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let versionLabel = UILabel()
        versionLabel.text = L10n.Settings.version(viewModel.appVersion)
        versionLabel.font = AppFont.regular(size: 12)
        versionLabel.textColor = .tertiaryLabel
        versionLabel.textAlignment = .center
        versionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        footerView.addSubview(byLabel)
        footerView.addSubview(versionLabel)
        
        NSLayoutConstraint.activate([
            byLabel.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 16),
            byLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor),
            
            versionLabel.topAnchor.constraint(equalTo: byLabel.bottomAnchor, constant: 4),
            versionLabel.centerXAnchor.constraint(equalTo: footerView.centerXAnchor)
        ])
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == viewModel.sections.count - 1 ? Constants.footerHeight : 0
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        viewModel.handleSelection(item: item)
        
        // Reload section for radio buttons to update checkmarks
        if item.type == .radio {
            tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = viewModel.sections[indexPath.section].items[indexPath.row]
        switch item.type {
        case .profile:
            return 78
        case .app:
            return 70
        case .appleSignIn:
            return 56
        default:
            return Constants.cellHeight
        }
    }
}
