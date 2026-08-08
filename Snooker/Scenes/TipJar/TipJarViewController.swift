//
//  TipJarViewController.swift
//  Snooker
//
//  Optional "Support the App" paywall: one-time tips (consumables) and monthly
//  support (auto-renewable subscriptions). No feature is gated — this is purely
//  voluntary support. Prices/names come from StoreKit (localized per region).
//

import UIKit
import StoreKit

final class TipJarViewController: UIViewController {

    // Live hosted documents; App Review requires both to be functional links
    // visible on this screen (Guideline 3.1.2(c)).
    private enum Links {
        /// Apple's standard EULA — must match the link in the App Store description.
        static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
        static let privacy = URL(string: "https://35coders.com/snooker/privacy")!
    }

    private enum Segment: Int {
        case oneTime = 0
        case monthly = 1
    }

    // MARK: - Dependencies

    private let store = TipStore()
    /// Default to Monthly support; the user can switch to one-time if they prefer.
    private var selectedSegment: Segment = .monthly

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["One-time", "Monthly"])
        control.selectedSegmentIndex = Segment.monthly.rawValue
        control.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        return control
    }()

    /// Holds the product rows; rebuilt whenever the segment or products change.
    private let productsStack = UIStackView()

    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private let footerLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = AppFont.regular(size: 12)
        // Same color as the intro text at the top of the screen.
        label.textColor = .secondaryLabel
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Support the App"
        view.backgroundColor = .systemGroupedBackground
        setupUI()
        loadProducts()
    }

    // MARK: - Setup

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        productsStack.axis = .vertical
        productsStack.spacing = 12

        contentStack.addArrangedSubview(makeHeaderView())
        contentStack.addArrangedSubview(segmentedControl)
        contentStack.addArrangedSubview(productsStack)
        contentStack.addArrangedSubview(loadingIndicator)
        contentStack.addArrangedSubview(makeRestoreButton())
        contentStack.addArrangedSubview(footerLabel)
        contentStack.addArrangedSubview(makeLegalLinksRow())

        let frameGuide = scrollView.frameLayoutGuide
        let contentGuide = scrollView.contentLayoutGuide

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: contentGuide.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: frameGuide.widthAnchor, constant: -40)
        ])
    }

    private func makeHeaderView() -> UIView {
        let heart = UILabel()
        heart.text = "❤️"
        heart.font = .systemFont(ofSize: 44)
        heart.textAlignment = .center

        let title = UILabel()
        title.text = "Enjoying the app?"
        title.font = AppFont.bold(size: 22)
        title.textColor = .label
        title.textAlignment = .center
        title.numberOfLines = 0

        let body = UILabel()
        body.text = """
        Hundreds of hours of work, heart and passion went into this app — built \
        to make following snooker simpler and more enjoyable. There are no paid \
        features: everything stays free. If it brought you a little joy, a small \
        optional tip helps me keep improving it. Thank you! 🙏
        """
        body.font = AppFont.regular(size: 15)
        body.textColor = .secondaryLabel
        body.textAlignment = .center
        body.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [heart, title, body])
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }

    private func makeRestoreButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Restore Purchases", for: .normal)
        button.titleLabel?.font = AppFont.medium(size: 15)
        button.addTarget(self, action: #selector(restoreTapped), for: .touchUpInside)
        return button
    }

    // MARK: - Products

    private func loadProducts() {
        loadingIndicator.startAnimating()
        Task {
            do {
                try await store.loadProducts()
                loadingIndicator.stopAnimating()
                rebuildProductRows()
            } catch {
                loadingIndicator.stopAnimating()
                showError("Could not load options. Please check your connection and try again.")
            }
        }
    }

    private func rebuildProductRows() {
        productsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let products = (selectedSegment == .oneTime)
            ? store.oneTimeProducts
            : store.subscriptionProducts

        if products.isEmpty {
            let empty = UILabel()
            empty.text = "No options available right now."
            empty.font = AppFont.regular(size: 15)
            empty.textColor = .tertiaryLabel
            empty.textAlignment = .center
            productsStack.addArrangedSubview(empty)
        } else {
            for product in products {
                productsStack.addArrangedSubview(makeProductRow(product))
            }
        }

        updateFooter()
    }

    private func makeProductRow(_ product: Product) -> UIView {
        let isActive = store.activeSubscriptionIDs.contains(product.id)
        let tint: UIColor = isActive ? .systemGreen : .systemBlue

        let titleLabel = UILabel()
        titleLabel.text = product.displayName
        titleLabel.font = AppFont.semiBold(size: 16)
        titleLabel.textColor = .label

        let descriptionLabel = UILabel()
        descriptionLabel.text = product.description
        descriptionLabel.font = AppFont.regular(size: 13)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        // Price is now a decorative pill (no nested button) — the whole card taps.
        let priceLabel = UILabel()
        priceLabel.text = isActive ? "Active" : product.displayPrice
        priceLabel.font = AppFont.semiBold(size: 17)
        priceLabel.textColor = tint
        priceLabel.textAlignment = .center
        // Safety net for long localized prices (e.g. "₺499,99").
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.7

        let priceStack = UIStackView(arrangedSubviews: [priceLabel])
        priceStack.axis = .vertical
        priceStack.alignment = .center
        priceStack.translatesAutoresizingMaskIntoConstraints = false

        // Guideline 3.1.2(c): the subscription length must be shown with the price.
        if !isActive, let periodText = Self.subscriptionPeriodText(for: product) {
            let periodLabel = UILabel()
            periodLabel.text = periodText
            periodLabel.font = AppFont.regular(size: 11)
            periodLabel.textColor = tint
            periodLabel.textAlignment = .center
            priceStack.addArrangedSubview(periodLabel)
        }

        let pill = UIView()
        pill.backgroundColor = tint.withAlphaComponent(0.15)
        pill.layer.cornerRadius = 18
        pill.translatesAutoresizingMaskIntoConstraints = false
        pill.addSubview(priceStack)
        pill.setContentHuggingPriority(.required, for: .horizontal)
        pill.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            // Grows to two lines ("₺x" + "per month") for subscriptions.
            pill.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            // Fixed width so every pill is identical regardless of the amount.
            pill.widthAnchor.constraint(equalToConstant: 108),
            priceStack.centerXAnchor.constraint(equalTo: pill.centerXAnchor),
            priceStack.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            priceStack.topAnchor.constraint(greaterThanOrEqualTo: pill.topAnchor, constant: 5),
            priceStack.bottomAnchor.constraint(lessThanOrEqualTo: pill.bottomAnchor, constant: -5),
            priceStack.leadingAnchor.constraint(greaterThanOrEqualTo: pill.leadingAnchor, constant: 10),
            priceStack.trailingAnchor.constraint(lessThanOrEqualTo: pill.trailingAnchor, constant: -10)
        ])

        let row = UIStackView(arrangedSubviews: [textStack, pill])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        row.translatesAutoresizingMaskIntoConstraints = false
        // Let taps fall through to the container button.
        row.isUserInteractionEnabled = false

        // The entire card is the tap target.
        let container = UIButton(type: .custom)
        container.backgroundColor = .secondarySystemGroupedBackground
        container.layer.cornerRadius = 14
        container.isEnabled = !isActive
        container.addSubview(row)
        container.addAction(UIAction { [weak self] _ in
            self?.purchase(product)
        }, for: .touchUpInside)
        // Subtle press feedback so it reads as tappable.
        let dim = UIAction { _ in container.alpha = 0.6 }
        let restore = UIAction { _ in container.alpha = 1.0 }
        container.addAction(dim, for: .touchDown)
        container.addAction(restore, for: [.touchUpInside, .touchUpOutside, .touchCancel])

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: container.topAnchor),
            row.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }

    private func updateFooter() {
        if selectedSegment == .monthly {
            footerLabel.text = """
            Monthly Support is an auto-renewable subscription. Each plan lasts \
            1 month and renews automatically at the price shown until cancelled. \
            Payment is charged to your Apple Account; you can cancel anytime in \
            your App Store subscription settings. No features are unlocked — \
            this is purely optional support.
            """
        } else {
            footerLabel.text = "A one-time tip. No subscription, no features unlocked — just a thank-you."
        }
    }

    /// "per month" etc. — read from StoreKit so it always matches the real product.
    private static func subscriptionPeriodText(for product: Product) -> String? {
        guard let period = product.subscription?.subscriptionPeriod else { return nil }
        let unit: String
        switch period.unit {
        case .day: unit = "day"
        case .week: unit = "week"
        case .month: unit = "month"
        case .year: unit = "year"
        @unknown default: return nil
        }
        return period.value == 1 ? "per \(unit)" : "per \(period.value) \(unit)s"
    }

    // MARK: - Actions

    @objc private func segmentChanged() {
        selectedSegment = Segment(rawValue: segmentedControl.selectedSegmentIndex) ?? .oneTime
        rebuildProductRows()
    }

    private func purchase(_ product: Product) {
        Task {
            do {
                let outcome = try await store.purchase(product)
                switch outcome {
                case .success:
                    rebuildProductRows()
                    showThankYou()
                case .pending:
                    showError("Your purchase is pending approval.")
                case .cancelled:
                    break
                }
            } catch {
                showError(error.localizedDescription)
            }
        }
    }

    @objc private func restoreTapped() {
        Task {
            await store.restore()
            rebuildProductRows()
        }
    }

    /// Always-visible, directly tappable legal links (required by 3.1.2(c) —
    /// hiding them behind an action sheet got the app rejected).
    private func makeLegalLinksRow() -> UIView {
        func linkButton(_ title: String, url: URL) -> UIButton {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
                .font: AppFont.medium(size: 13),
                .underlineStyle: NSUnderlineStyle.single.rawValue
            ]))
            let button = UIButton(configuration: config)
            button.addAction(UIAction { _ in UIApplication.shared.open(url) }, for: .touchUpInside)
            return button
        }

        let separator = UILabel()
        separator.text = "·"
        separator.font = AppFont.regular(size: 13)
        separator.textColor = .secondaryLabel

        let row = UIStackView(arrangedSubviews: [
            linkButton("Terms of Use (EULA)", url: Links.terms),
            separator,
            linkButton("Privacy Policy", url: Links.privacy)
        ])
        row.axis = .horizontal
        row.spacing = 6
        row.alignment = .center

        // Wrapper keeps the row centered instead of stretched full-width.
        let wrapper = UIStackView(arrangedSubviews: [row])
        wrapper.axis = .vertical
        wrapper.alignment = .center
        return wrapper
    }

    // MARK: - Feedback

    private func showThankYou() {
        let alert = UIAlertController(
            title: "Thank you! ❤️",
            message: "Your support genuinely means a lot and helps keep the app growing.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "You're welcome", style: .default))
        present(alert, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Something went wrong", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
