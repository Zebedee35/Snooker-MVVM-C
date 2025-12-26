//
//  SeasonListViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

final class SeasonListViewController: UIViewController {
  
  private let collectionView: UICollectionView = {
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .vertical
    layout.minimumLineSpacing = 0
    layout.minimumInteritemSpacing = 0
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.register(SeasonListCell.self, forCellWithReuseIdentifier: SeasonListCell.identifier)
    collectionView.backgroundColor = .clear
    collectionView.alwaysBounceVertical = true
    collectionView.contentInsetAdjustmentBehavior = .automatic
    return collectionView
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
  
  private var hasLoadedData = false
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemBackground
    title = "Seasons"
    
    setupUI()
    setupConstraints()
    
    collectionView.delegate = self
    collectionView.dataSource = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.prefersLargeTitles = true
    navigationItem.largeTitleDisplayMode = .always
    
    // Lazy loading - sadece ilk görünümde yükle
    if !hasLoadedData {
      hasLoadedData = true
      viewModel.loadData()
    }
  }
  
  private func setupUI() {
    view.addSubview(collectionView)
    view.addSubview(activityIndicator)
  }
  
  private func setupConstraints() {
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: view.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      
      activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }
}

// MARK: - UICollectionViewDataSource
extension SeasonListViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return cellPresentations.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SeasonListCell.identifier, for: indexPath) as? SeasonListCell else {
      return UICollectionViewCell()
    }
    
    let presentation = cellPresentations[indexPath.item]
    cell.configure(with: presentation)
    return cell
  }
}

// MARK: - UICollectionViewDelegate
extension SeasonListViewController: UICollectionViewDelegate {
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    viewModel.selectSeason(at: indexPath.item)
  }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension SeasonListViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.bounds.width, height: 80)
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
      collectionView.reloadData()
      
      // Data yüklendikten sonra bugünden sonraki ilk turnuvaya scroll yap
      scrollToUpcomingTournament()
    }
  }
  
  func navigate(to route: SeasonListRoute) {
    coordinator?.handle(route: route)
  }
  
  // MARK: - Auto Scroll
  
  /// Bugünden sonraki ilk turnuvayı bulup ekranın ortasına scroll yapar
  private func scrollToUpcomingTournament() {
    guard !cellPresentations.isEmpty else { return }
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let today = Date()
    
    // Bugünden sonraki ilk turnuvayı bul (isPast == false olan ilk item)
    // veya startDate >= today olan ilk item
    var targetIndex: Int?
    
    for (index, presentation) in cellPresentations.enumerated() {
      // Önce isPast property'sine bak
      if !presentation.isPast {
        targetIndex = index
        break
      }
      
      // Alternatif olarak startDate'i kontrol et
      if let startDate = dateFormatter.date(from: presentation.startDateString),
         startDate >= today {
        targetIndex = index
        break
      }
    }
    
    // Eğer gelecek turnuva bulunamadıysa, en son turnuvaya git
    guard let index = targetIndex, index < cellPresentations.count else { return }
    
    // CollectionView layout'unun tamamlanmasını bekle
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
      guard let self = self else { return }
      
      let indexPath = IndexPath(item: index, section: 0)
      
      // Scroll to item with animation - ekranın ortasında olacak şekilde
      self.collectionView.scrollToItem(
        at: indexPath,
        at: .centeredVertically,
        animated: true
      )
    }
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
  func fetchSeasons() async throws -> [TournamentDTO] {
    // Simulate network delay
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    return TournamentDTO.previewList
  }
}

#endif
