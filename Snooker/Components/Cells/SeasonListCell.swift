//
//  SeasonListCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 3.11.2025.
//

import UIKit

final class SeasonListCell: UICollectionViewCell {
    static let identifier = "SeasonListCell"
    
    // MARK: - Constants
    
    private enum Constants {
        static let cellHeight: CGFloat = 80
        static let cornerRadius: CGFloat = 12
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 12
        static let spacing: CGFloat = 12
        static let titleFontSize: CGFloat = 16
        static let subtitleFontSize: CGFloat = 13
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tournamentDateView: TournamentDateView = {
        let view = TournamentDateView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tournamentNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.titleFontSize, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: Constants.subtitleFontSize, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "chevron.right")
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        contentView.addSubview(containerView)
        containerView.addSubview(tournamentDateView)
        containerView.addSubview(infoStackView)
        containerView.addSubview(chevronImageView)
        
        infoStackView.addArrangedSubview(tournamentNameLabel)
        infoStackView.addArrangedSubview(locationLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
            
            // Tournament Date View (Left)
            tournamentDateView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            tournamentDateView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Info Stack (Center)
            infoStackView.leadingAnchor.constraint(equalTo: tournamentDateView.trailingAnchor, constant: Constants.spacing),
            infoStackView.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -Constants.spacing),
            infoStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            // Chevron (Right)
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.widthAnchor.constraint(equalToConstant: 12),
            chevronImageView.heightAnchor.constraint(equalToConstant: 16),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with presentation: SeasonListCellPresentation) {
        tournamentNameLabel.text = presentation.name
        locationLabel.text = presentation.location
        
        // Tarih view'ını yapılandır
        tournamentDateView.configure(
            startDateString: presentation.startDateString,
            endDateString: presentation.endDateString
        )
        
        // Geçmiş turnuva için opacity ayarla
        if presentation.isPast {
            tournamentNameLabel.textColor = .secondaryLabel
            chevronImageView.tintColor = .quaternaryLabel
        } else {
            tournamentNameLabel.textColor = .label
            chevronImageView.tintColor = .tertiaryLabel
        }
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        tournamentNameLabel.text = nil
        locationLabel.text = nil
        tournamentNameLabel.textColor = .label
        chevronImageView.tintColor = .tertiaryLabel
    }
}

// MARK: - Previews
#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct SeasonListCell_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Active Tournament
            SeasonListCellPreviewWrapper(isPast: false)
                .frame(height: 88)
                .previewDisplayName("Active Tournament")
            
            // Past Tournament
            SeasonListCellPreviewWrapper(isPast: true)
                .frame(height: 88)
                .previewDisplayName("Past Tournament")
            
            // Dark Mode
            SeasonListCellPreviewWrapper(isPast: false)
                .frame(height: 88)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // List Preview
            SeasonListCellListPreviewWrapper()
                .previewDisplayName("Cell List")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct SeasonListCellPreviewWrapper: UIViewRepresentable {
    let isPast: Bool
    
    func makeUIView(context: Context) -> UICollectionViewCell {
        let cell = SeasonListCell(frame: CGRect(x: 0, y: 0, width: 375, height: 88))
        
        // Manuel presentation oluştur
        let tournament = TournamentDTO(
            id: "1",
            season: 2025,
            name: "World Championship 2025",
            startDate: isPast ? "2024-04-20" : "2028-04-20",
            endDate: isPast ? "2024-04-26" : "2028-04-26",
            city: "Sheffield",
            country: "England",
            venue: "Crucible Theatre",
            continent: nil
        )
        let presentation = SeasonListCellPresentation(tournament: tournament)
        cell.configure(with: presentation)
        return cell
    }
    
    func updateUIView(_ uiView: UICollectionViewCell, context: Context) {}
}

@available(iOS 13.0, *)
private struct SeasonListCellListPreviewWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = SeasonListPreviewCollectionViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private class SeasonListPreviewCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private var collectionView: UICollectionView!
    
    private let tournaments: [TournamentDTO] = [
        TournamentDTO(
            id: "1",
            season: 2024,
            name: "UK Championship 2024",
            startDate: "2024-11-23",
            endDate: "2024-12-01",
            city: "York",
            country: "England",
            venue: "Barbican Centre",
            continent: nil
        ),
        TournamentDTO(
            id: "2",
            season: 2025,
            name: "Masters 2025",
            startDate: "2025-01-12",
            endDate: "2025-01-19",
            city: "London",
            country: "England",
            venue: "Alexandra Palace",
            continent: nil
        ),
        TournamentDTO(
            id: "3",
            season: 2025,
            name: "World Championship 2025",
            startDate: "2025-04-19",
            endDate: "2025-05-05",
            city: "Sheffield",
            country: "England",
            venue: "Crucible Theatre",
            continent: nil
        )
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.register(SeasonListCell.self, forCellWithReuseIdentifier: SeasonListCell.identifier)
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        title = "Season List"
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tournaments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SeasonListCell.identifier, for: indexPath) as? SeasonListCell else {
            return UICollectionViewCell()
        }
        let presentation = SeasonListCellPresentation(tournament: tournaments[indexPath.item])
        cell.configure(with: presentation)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: 88)
    }
}
#endif
