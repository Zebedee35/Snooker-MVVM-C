//
//  SeasonListViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 6.10.2025.
//

import UIKit

final class SeasonListViewController: UIViewController {
  
  private var scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()
  
  private var contentView: UIView = {
    let contentView = UIView()
    contentView.translatesAutoresizingMaskIntoConstraints = false
    return contentView
  }()
  
  private let titleLabel: UILabel = {
    let label = UILabel()
    label.text = "Season List Screen"
    label.font = .systemFont(ofSize: 24, weight: .bold)
    label.textColor = .white
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()

  var coordinator: SeasonListCoordinator?
  var viewModel: SeasonListViewModelProtocol! {
    didSet {
//      viewModel.delegate = self
    }
  }
  
  
  init() {
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .systemOrange

    setupUI()
    setupConstraints()
//    viewModel.loadData()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.navigationBar.prefersLargeTitles = false
  }
  
  private func setupUI() {
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    contentView.addSubview(titleLabel)
  }
  
  private func setupConstraints() {
    NSLayoutConstraint.activate([
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
      
      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
      contentView.heightAnchor.constraint(equalTo: scrollView.heightAnchor), // Bu satırı ekledim
      
      // Title label constraints
      titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    ])
  }
  

}
