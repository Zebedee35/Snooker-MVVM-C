//
//  SeasonListViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

final class SeasonListViewController: UIViewController {
  
  private let tableView: UITableView = {
    let tableView = UITableView(frame: .zero, style: .plain)
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.register(SeasonListCell.self, forCellReuseIdentifier: SeasonListCell.identifier)
    tableView.backgroundColor = .systemBackground
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 80
    return tableView
  }()
  
  private let activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .large)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = true
    return indicator
  }()

  var viewModel: SeasonListViewModelProtocol! {
    didSet {
       viewModel.delegate = self
    }
  }
  
  var cellPresentations: [SeasonListCellPresentation] = []
  var coordinator: SeasonListCoordinator?

  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    title = "Seasons"
    
    setupUI()
    setupConstraints()
    
    tableView.delegate = self
    tableView.dataSource = self
    
    viewModel.loadData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.prefersLargeTitles = true
  }
  
  private func setupUI() {
    view.addSubview(tableView)
    view.addSubview(activityIndicator)
  }
  
  private func setupConstraints() {
    NSLayoutConstraint.activate([
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }
}

// MARK: - UITableViewDataSource
extension SeasonListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return cellPresentations.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: SeasonListCell.identifier, for: indexPath) as? SeasonListCell else {
      return UITableViewCell()
    }
    
    let presentation = cellPresentations[indexPath.row]
    cell.configure(with: presentation)
    return cell
  }
}

// MARK: - UITableViewDelegate
extension SeasonListViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    viewModel.selectSeason(at: indexPath.row)
  }
}

// MARK: - SeasonListViewModelDelegate
extension SeasonListViewController: SeasonListViewModelDelegate {
  func handleOutput(_ output: SeasonListViewModelOutput) {
    switch output {
    case .showLoading(let isLoading):
      if isLoading {
        activityIndicator.startAnimating()
      } else {
        activityIndicator.stopAnimating()
      }
    case .displaySeasons(let presentations):
      cellPresentations = presentations
      tableView.reloadData()
    }
  }
  
  func navigate(to route: SeasonListRoute) {
    coordinator?.handle(route: route)
  }
}

// MARK: - SeasonListCell
final class SeasonListCell: UITableViewCell {
  static let identifier = "SeasonListCell"
  
  private let tournamentNameLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 17, weight: .semibold)
    label.textColor = .label
    label.numberOfLines = 0
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private let dateLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private let locationLabel: UILabel = {
    let label = UILabel()
    label.font = .systemFont(ofSize: 14, weight: .regular)
    label.textColor = .secondaryLabel
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  private let stackView: UIStackView = {
    let stack = UIStackView()
    stack.axis = .vertical
    stack.spacing = 4
    stack.translatesAutoresizingMaskIntoConstraints = false
    return stack
  }()
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func setupUI() {
    contentView.addSubview(stackView)
    stackView.addArrangedSubview(tournamentNameLabel)
    stackView.addArrangedSubview(dateLabel)
    stackView.addArrangedSubview(locationLabel)
    
    NSLayoutConstraint.activate([
      stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
      stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
    ])
  }
  
  func configure(with presentation: SeasonListCellPresentation) {
    tournamentNameLabel.text = presentation.name
    dateLabel.text = presentation.dateRange
    locationLabel.text = presentation.location
  }
}
