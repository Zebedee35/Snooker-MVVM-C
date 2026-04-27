//
//  AnnouncementsHistoryViewController.swift
//  Snooker
//

import UIKit

final class AnnouncementsHistoryViewController: UIViewController {

    // MARK: - UI

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemBackground
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 80
        tv.dataSource = self
        tv.register(AnnouncementHistoryCell.self, forCellReuseIdentifier: AnnouncementHistoryCell.reuseIdentifier)
        return tv
    }()

    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "No dismissed announcements yet."
        label.font = AppFont.regular(size: 15)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    // MARK: - Data

    private var records: [DismissedAnnouncementRecord] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Announcements"
        view.backgroundColor = .systemBackground
        setupUI()
        loadRecords()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func loadRecords() {
        records = AnnouncementManager.shared.dismissedAnnouncementsHistory()
        emptyLabel.isHidden = !records.isEmpty
        tableView.isHidden = records.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension AnnouncementsHistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        records.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: AnnouncementHistoryCell.reuseIdentifier,
            for: indexPath
        ) as? AnnouncementHistoryCell else {
            return UITableViewCell()
        }
        cell.configure(with: records[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        records.isEmpty ? nil : "DISMISSED ANNOUNCEMENTS"
    }
}
