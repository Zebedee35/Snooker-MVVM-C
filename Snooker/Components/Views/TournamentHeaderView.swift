//
//  TournamentHeaderView.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 26.12.2025.
//

import UIKit

/// Turnuva detay bilgilerini gösteren header view
/// CollectionView'da section header olarak kullanılır
final class TournamentHeaderView: UICollectionReusableView {
    
    static let identifier = "TournamentHeaderView"
    static let preferredHeight: CGFloat = 180
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let iconSize: CGFloat = 20
        static let spacing: CGFloat = 12
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Gradient overlay for visual appeal
    private let gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor.systemGreen.withAlphaComponent(0.15).cgColor,
            UIColor.clear.cgColor
        ]
        layer.locations = [0.0, 1.0]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    // Tournament Name
    private let tournamentNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Divider line
    private let dividerView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Location Stack (Country, City, Venue)
    private let locationIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "mappin.and.ellipse")
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var locationStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [locationIconView, locationLabel])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Venue Stack
    private let venueIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "building.2")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let venueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var venueStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [venueIconView, venueLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Date Stack
    private let dateIconView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "calendar")
        imageView.tintColor = .systemOrange
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var dateStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dateIconView, dateLabel])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Info Container Stack
    private lazy var infoStackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [locationStack, venueStack, dateStack])
        stack.axis = .vertical
        stack.alignment = .leading
        stack.spacing = Constants.spacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = containerView.bounds
        gradientLayer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(containerView)
        containerView.layer.insertSublayer(gradientLayer, at: 0)
        
        containerView.addSubview(tournamentNameLabel)
        containerView.addSubview(dividerView)
        containerView.addSubview(infoStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            // Tournament Name
            tournamentNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.verticalPadding),
            tournamentNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            tournamentNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Divider
            dividerView.topAnchor.constraint(equalTo: tournamentNameLabel.bottomAnchor, constant: 12),
            dividerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            dividerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            dividerView.heightAnchor.constraint(equalToConstant: 1),
            
            // Info Stack
            infoStackView.topAnchor.constraint(equalTo: dividerView.bottomAnchor, constant: 14),
            infoStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.horizontalPadding),
            infoStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Icon sizes
            locationIconView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            locationIconView.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            venueIconView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            venueIconView.heightAnchor.constraint(equalToConstant: Constants.iconSize),
            dateIconView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            dateIconView.heightAnchor.constraint(equalToConstant: Constants.iconSize),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(
        name: String,
        country: String?,
        city: String?,
        venue: String?,
        startDate: String,
        endDate: String
    ) {
        tournamentNameLabel.text = name
        
        // Location (City, Country)
        var locationParts: [String] = []
        if let city = city, !city.isEmpty {
            locationParts.append(city)
        }
        if let country = country, !country.isEmpty {
            locationParts.append(country)
        }
        locationLabel.text = locationParts.isEmpty ? "Location TBD" : locationParts.joined(separator: ", ")
        
        // Venue
        if let venue = venue, !venue.isEmpty {
            venueLabel.text = venue
            venueStack.isHidden = false
        } else {
            venueStack.isHidden = true
        }
        
        // Dates
        dateLabel.text = formatDateRange(start: startDate, end: endDate)
    }
    
    /// TournamentWithMatchesDTO için convenience method
    func configure(with tournament: TournamentHeaderPresentation) {
        configure(
            name: tournament.name,
            country: tournament.country,
            city: tournament.city,
            venue: tournament.venue,
            startDate: tournament.startDate,
            endDate: tournament.endDate
        )
    }
    
    // MARK: - Helpers
    
    private func formatDateRange(start: String, end: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let startDate = inputFormatter.date(from: start),
              let endDate = inputFormatter.date(from: end) else {
            return "\(start) - \(end)"
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.locale = Locale.current
        
        let calendar = Calendar.current
        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)
        
        if startMonth == endMonth {
            // Aynı ay: "20 - 06 May 2024"
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "d"
            
            outputFormatter.dateFormat = "d MMM yyyy"
            let startDay = dayFormatter.string(from: startDate)
            let endFormatted = outputFormatter.string(from: endDate)
            
            return "\(startDay) - \(endFormatted)"
        } else {
            // Farklı ay: "20 Apr - 06 May 2024"
            outputFormatter.dateFormat = "d MMM"
            let startFormatted = outputFormatter.string(from: startDate)
            
            outputFormatter.dateFormat = "d MMM yyyy"
            let endFormatted = outputFormatter.string(from: endDate)
            
            return "\(startFormatted) - \(endFormatted)"
        }
    }
}

// MARK: - TournamentHeaderPresentation

struct TournamentHeaderPresentation {
    let name: String
    let country: String?
    let city: String?
    let venue: String?
    let startDate: String
    let endDate: String
    
    init(tournament: TournamentWithMatchesDTO) {
        self.name = tournament.name
        self.country = tournament.country
        self.city = tournament.city
        self.venue = tournament.venue
        self.startDate = tournament.startDate
        self.endDate = tournament.endDate
    }
    
    init(
        name: String,
        country: String?,
        city: String?,
        venue: String?,
        startDate: String,
        endDate: String
    ) {
        self.name = name
        self.country = country
        self.city = city
        self.venue = venue
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Preview

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct TournamentHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TournamentHeaderViewPreviewWrapper()
                .frame(height: 180)
                .previewDisplayName("Light Mode")
            
            TournamentHeaderViewPreviewWrapper()
                .frame(height: 180)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Without venue
            TournamentHeaderViewPreviewWrapper(showVenue: false)
                .frame(height: 160)
                .previewDisplayName("No Venue")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

@available(iOS 13.0, *)
private struct TournamentHeaderViewPreviewWrapper: UIViewRepresentable {
    var showVenue: Bool = true
    
    func makeUIView(context: Context) -> TournamentHeaderView {
        let view = TournamentHeaderView()
        view.configure(
            name: "Cazoo World Championship 2024",
            country: "England",
            city: "Sheffield",
            venue: showVenue ? "Crucible Theatre" : nil,
            startDate: "2024-04-20",
            endDate: "2024-05-06"
        )
        return view
    }
    
    func updateUIView(_ uiView: TournamentHeaderView, context: Context) {}
}
#endif
