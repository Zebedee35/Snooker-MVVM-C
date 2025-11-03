//
//  SeasonListCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 3.11.2025.
//

import UIKit

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

// MARK: - Preview Helpers

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

#endif
