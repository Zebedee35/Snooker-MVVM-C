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

// MARK: - Previews
#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct SeasonListViewController_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Preview with mock data
      UIViewControllerPreview {
        let viewController = SeasonListViewController()
        let mockService = MockSeasonListService()
        let viewModel = SeasonListViewModel(service: mockService)
        viewController.viewModel = viewModel
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
      }
      .previewDisplayName("Season List - Light")
      
      UIViewControllerPreview {
        let viewController = SeasonListViewController()
        let mockService = MockSeasonListService()
        let viewModel = SeasonListViewModel(service: mockService)
        viewController.viewModel = viewModel
        
        let navController = UINavigationController(rootViewController: viewController)
        return navController
      }
      .preferredColorScheme(.dark)
      .previewDisplayName("Season List - Dark")
    }
  }
}

@available(iOS 13.0, *)
struct SeasonListCell_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Single cell preview - Light
      CellPreviewContainer {
        let cell = SeasonListCell(style: .default, reuseIdentifier: SeasonListCell.identifier)
        let presentation = SeasonListCellPresentation(tournament: TournamentDTO.preview)
        cell.configure(with: presentation)
        return cell
      }
      .previewDisplayName("Cell - Light")
      
      // Single cell preview - Dark
      CellPreviewContainer {
        let cell = SeasonListCell(style: .default, reuseIdentifier: SeasonListCell.identifier)
        let presentation = SeasonListCellPresentation(tournament: TournamentDTO.preview)
        cell.configure(with: presentation)
        return cell
      }
      .preferredColorScheme(.dark)
      .previewDisplayName("Cell - Dark")
    }
  }
}

// MARK: - Cell Preview Container
@available(iOS 13.0, *)
struct CellPreviewContainer<Content: UIView>: View {
  let content: Content
  let width: CGFloat
  let height: CGFloat
  
  init(width: CGFloat = 375, height: CGFloat = 88, @ViewBuilder builder: () -> Content) {
    self.content = builder()
    self.width = width
    self.height = height
  }
  
  var body: some View {
    UIViewPreviewWrapper(view: content)
      .frame(width: width, height: height)
      .previewLayout(.sizeThatFits)
  }
}

@available(iOS 13.0, *)
struct UIViewPreviewWrapper<View: UIView>: UIViewRepresentable {
  let view: View
  
  func makeUIView(context: Context) -> UIView {
    let container = UIView(frame: .zero)
    container.addSubview(view)
    view.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: container.topAnchor),
      view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
    ])
    return container
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview TableView DataSource
final class PreviewTableViewDataSource: NSObject, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return TournamentDTO.previewList.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: SeasonListCell.identifier, for: indexPath) as? SeasonListCell else {
      return UITableViewCell()
    }
    let presentation = SeasonListCellPresentation(tournament: TournamentDTO.previewList[indexPath.row])
    cell.configure(with: presentation)
    return cell
  }
}

// MARK: - Preview Helpers

@available(iOS 13.0, *)
struct UIViewControllerPreview<ViewController: UIViewController>: UIViewControllerRepresentable {
  let viewController: ViewController
  
  init(_ builder: @escaping () -> ViewController) {
    viewController = builder()
  }
  
  func makeUIViewController(context: Context) -> ViewController {
    return viewController
  }
  
  func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

// MARK: - Mock Service for Preview

final class MockSeasonListService: SeasonListServiceProtocol {
  func fetchSeasons(completion: @escaping (Result<[TournamentDTO], Error>) -> Void) {
    // Simulate network delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      completion(.success(TournamentDTO.previewList))
    }
  }
}

#endif
