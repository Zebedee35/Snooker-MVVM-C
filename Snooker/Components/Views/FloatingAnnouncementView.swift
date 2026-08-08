//
//  FloatingAnnouncementView.swift
//  Snooker
//
//  Created by GitHub Copilot on 22.04.2026.
//

import UIKit

final class FloatingAnnouncementView: UIView {

    var onCloseTapped: (() -> Void)?

    private enum Constants {
        static let cornerRadius: CGFloat = 14
        static let horizontalPadding: CGFloat = 14
        static let verticalPadding: CGFloat = 12
        static let closeButtonSize: CGFloat = 28
        static let iconSize: CGFloat = 20
        static let accentWidth: CGFloat = 4
    }

    private let cardView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.16
        view.layer.shadowRadius = 12
        view.layer.shadowOffset = CGSize(width: 0, height: 4)
        return view
    }()

    private let accentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemBlue
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let typeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppFont.bold(size: 14)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = AppFont.regular(size: 14)
        label.textColor = .label
        label.numberOfLines = 6
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .tertiaryLabel
        button.accessibilityLabel = "Close announcement"
        return button
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [typeLabel, contentLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .fill
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with announcement: AppAnnouncementDTO) {
        let style = AnnouncementVisualStyle(type: announcement.announcementKind)

        accentView.backgroundColor = style.tintColor
        iconImageView.image = UIImage(systemName: style.iconName)
        iconImageView.tintColor = style.tintColor
        typeLabel.text = style.title
        contentLabel.text = announcement.sanitizedContent

        accessibilityLabel = "\(style.title): \(announcement.sanitizedContent)"
    }

    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        addSubview(cardView)
        cardView.addSubview(accentView)
        cardView.addSubview(iconImageView)
        cardView.addSubview(closeButton)
        cardView.addSubview(textStackView)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            accentView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            accentView.topAnchor.constraint(equalTo: cardView.topAnchor),
            accentView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),
            accentView.widthAnchor.constraint(equalToConstant: Constants.accentWidth),

            iconImageView.leadingAnchor.constraint(equalTo: accentView.trailingAnchor, constant: Constants.horizontalPadding),
            iconImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Constants.verticalPadding),
            iconImageView.widthAnchor.constraint(equalToConstant: Constants.iconSize),
            iconImageView.heightAnchor.constraint(equalToConstant: Constants.iconSize),

            closeButton.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -8),
            closeButton.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 6),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.closeButtonSize),

            textStackView.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 10),
            textStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: Constants.verticalPadding),
            textStackView.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -8),
            textStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -Constants.verticalPadding),

            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 58)
        ])
    }

    @objc private func closeTapped() {
        onCloseTapped?()
    }
}

private struct AnnouncementVisualStyle {
    let title: String
    let iconName: String
    let tintColor: UIColor

    init(type: AnnouncementType) {
        switch type {
        case .error:
            title = L10n.Announcements.Kind.error
            iconName = "exclamationmark.octagon.fill"
            tintColor = .systemRed
        case .warning:
            title = L10n.Announcements.Kind.warning
            iconName = "exclamationmark.triangle.fill"
            tintColor = .systemOrange
        case .info:
            title = L10n.Announcements.Kind.info
            iconName = "info.circle.fill"
            tintColor = .systemBlue
        case .success:
            title = L10n.Announcements.Kind.success
            iconName = "checkmark.circle.fill"
            tintColor = .systemGreen
        }
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct FloatingAnnouncementView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FloatingAnnouncementPreviewWrapper(announcement: .previewError)
                .frame(width: 390, height: 120)
                .previewDisplayName("Error - Top")

            FloatingAnnouncementPreviewWrapper(announcement: .previewInfo)
                .frame(width: 390, height: 110)
                .previewDisplayName("Info - Bottom")

            FloatingAnnouncementPreviewWrapper(announcement: .previewWarning)
                .frame(width: 390, height: 130)
                .previewDisplayName("Warning - Timed")

            FloatingAnnouncementPreviewWrapper(announcement: .previewSuccess)
                .frame(width: 390, height: 110)
                .preferredColorScheme(.dark)
                .previewDisplayName("Success - Dark")
        }
        .background(Color(.systemBackground))
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct FloatingAnnouncementPreviewWrapper: UIViewRepresentable {
    let announcement: AppAnnouncementDTO

    func makeUIView(context: Context) -> FloatingAnnouncementView {
        let view = FloatingAnnouncementView()
        view.configure(with: announcement)
        return view
    }

    func updateUIView(_ uiView: FloatingAnnouncementView, context: Context) {
        uiView.configure(with: announcement)
    }
}

private extension AppAnnouncementDTO {
    static var previewError: AppAnnouncementDTO {
        AppAnnouncementDTO(
            id: "preview-error",
            announcementKind: .error,
            content: "LiveScore service is currently experiencing a temporary outage. Our team is working on it.",
            expiresAt: nil,
            displayMode: .persistent,
            placementZone: .top,
            displayRank: 100,
            isActive: true,
            createdAt: "2026-04-22T08:25:19+00:00"
        )
    }

    static var previewInfo: AppAnnouncementDTO {
        AppAnnouncementDTO(
            id: "preview-info",
            announcementKind: .info,
            content: "If you enjoy using the app, you can support us from Settings.",
            expiresAt: nil,
            displayMode: .oneTime,
            placementZone: .bottom,
            displayRank: 50,
            isActive: true,
            createdAt: "2026-04-22T08:25:19+00:00"
        )
    }

    static var previewWarning: AppAnnouncementDTO {
        AppAnnouncementDTO(
            id: "preview-warning",
            announcementKind: .warning,
            content: "2027 season data will be uploaded in June. Until then, some match details may be unavailable.",
            expiresAt: "2026-06-11T08:25:19+00:00",
            displayMode: .oneTime,
            placementZone: .top,
            displayRank: 80,
            isActive: true,
            createdAt: "2026-04-22T08:25:19+00:00"
        )
    }

    static var previewSuccess: AppAnnouncementDTO {
        AppAnnouncementDTO(
            id: "preview-success",
            announcementKind: .success,
            content: "Background sync completed. Latest rankings are up to date.",
            expiresAt: nil,
            displayMode: .persistent,
            placementZone: .bottom,
            displayRank: 40,
            isActive: true,
            createdAt: "2026-04-22T08:25:19+00:00"
        )
    }
}
#endif
