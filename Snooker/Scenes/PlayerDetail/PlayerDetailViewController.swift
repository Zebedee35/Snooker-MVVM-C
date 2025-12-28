//
//  PlayerDetailViewController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 28.12.2025.
//

import UIKit

final class PlayerDetailViewController: UIViewController {
    
    // MARK: - Constants
    
    private enum Constants {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 16
        static let cornerRadius: CGFloat = 16
        static let spacing: CGFloat = 12
        static let statItemSpacing: CGFloat = 8
    }
    
    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Header Section
    private let headerContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let playerImageView: PlayerImageView = {
        let imageView = PlayerImageView(size: .extraLarge)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let flagLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 24)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let countryLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rankBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let rankLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 18)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Bio Section
    private let bioContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bioTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Biography"
        label.font = AppFont.semiBold(size: 18)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var bioStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Constants.statItemSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Close Button
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .secondaryLabel
        button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Properties
    
    private let presentation: PlayerDetailPresentation
    
    // MARK: - Init
    
    init(presentation: PlayerDetailPresentation) {
        self.presentation = presentation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        configure(with: presentation)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        view.addSubview(closeButton)
        
        scrollView.addSubview(contentView)
        
        // Header
        contentView.addSubview(headerContainerView)
        headerContainerView.addSubview(playerImageView)
        headerContainerView.addSubview(flagLabel)
        headerContainerView.addSubview(nameLabel)
        headerContainerView.addSubview(countryLabel)
        headerContainerView.addSubview(rankBadgeView)
        rankBadgeView.addSubview(rankLabel)
        
        // Bio
        contentView.addSubview(bioContainerView)
        bioContainerView.addSubview(bioTitleLabel)
        bioContainerView.addSubview(bioStackView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Close Button
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            // ScrollView
            scrollView.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // ContentView
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            // Header Container
            headerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalPadding),
            headerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            headerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Player Image
            playerImageView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: Constants.verticalPadding),
            playerImageView.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            
            // Flag
            flagLabel.topAnchor.constraint(equalTo: playerImageView.bottomAnchor, constant: 12),
            flagLabel.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            
            // Name
            nameLabel.topAnchor.constraint(equalTo: flagLabel.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: Constants.horizontalPadding),
            nameLabel.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            // Country
            countryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            countryLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: Constants.horizontalPadding),
            countryLabel.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -Constants.horizontalPadding),
            countryLabel.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: -Constants.verticalPadding),
            
            // Rank Badge
            rankBadgeView.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: Constants.verticalPadding),
            rankBadgeView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -Constants.horizontalPadding),
            rankBadgeView.widthAnchor.constraint(equalToConstant: 40),
            rankBadgeView.heightAnchor.constraint(equalToConstant: 40),
            
            rankLabel.centerXAnchor.constraint(equalTo: rankBadgeView.centerXAnchor),
            rankLabel.centerYAnchor.constraint(equalTo: rankBadgeView.centerYAnchor),
            
            // Bio Container
            bioContainerView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: Constants.spacing),
            bioContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Constants.horizontalPadding),
            bioContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Constants.horizontalPadding),
            bioContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalPadding),
            
            bioTitleLabel.topAnchor.constraint(equalTo: bioContainerView.topAnchor, constant: Constants.verticalPadding),
            bioTitleLabel.leadingAnchor.constraint(equalTo: bioContainerView.leadingAnchor, constant: Constants.horizontalPadding),
            bioTitleLabel.trailingAnchor.constraint(equalTo: bioContainerView.trailingAnchor, constant: -Constants.horizontalPadding),
            
            bioStackView.topAnchor.constraint(equalTo: bioTitleLabel.bottomAnchor, constant: 12),
            bioStackView.leadingAnchor.constraint(equalTo: bioContainerView.leadingAnchor, constant: Constants.horizontalPadding),
            bioStackView.trailingAnchor.constraint(equalTo: bioContainerView.trailingAnchor, constant: -Constants.horizontalPadding),
            bioStackView.bottomAnchor.constraint(equalTo: bioContainerView.bottomAnchor, constant: -Constants.verticalPadding)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Configure
    
    private func configure(with presentation: PlayerDetailPresentation) {
        // Header
        playerImageView.configure(with: presentation.photoUrl)
        flagLabel.text = presentation.flagEmoji
        
        // Name with styled surname
        let attributedName = createStyledName(firstName: presentation.firstName, surname: presentation.surname)
        nameLabel.attributedText = attributedName
        
        countryLabel.text = presentation.country
        
        // Rank
        if let rank = presentation.rank {
            rankLabel.text = "#\(rank)"
            rankBadgeView.isHidden = false
        } else {
            rankBadgeView.isHidden = true
        }
        
        // Bio Items
        configureBioSection(with: presentation)
    }
    
    private func createStyledName(firstName: String, surname: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString()
        
        let firstNameAttrs: [NSAttributedString.Key: Any] = [
            .font: AppFont.regular(size: 24),
            .foregroundColor: UIColor.label
        ]
        
        let surnameAttrs: [NSAttributedString.Key: Any] = [
            .font: AppFont.bold(size: 24),
            .foregroundColor: UIColor.label
        ]
        
        attributedString.append(NSAttributedString(string: firstName + " ", attributes: firstNameAttrs))
        attributedString.append(NSAttributedString(string: surname.uppercased(), attributes: surnameAttrs))
        
        return attributedString
    }
    
    private func configureBioSection(with presentation: PlayerDetailPresentation) {
        bioStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Birth Date & Age
        if let birthDate = presentation.formattedBirthDate {
            var value = birthDate
            if let age = presentation.age {
                value += " (\(age) years old)"
            }
            bioStackView.addArrangedSubview(createStatRow(icon: "birthday.cake", title: "Born", value: value))
        }
        
        // Turned Pro
        if let turnedPro = presentation.turnedPro {
            var value = "\(turnedPro)"
            if let years = presentation.yearsAsPro {
                value += " (\(years) years)"
            }
            bioStackView.addArrangedSubview(createStatRow(icon: "star.fill", title: "Turned Pro", value: value))
        }
        
        // Empty state if no bio info
        if bioStackView.arrangedSubviews.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No biography available"
            emptyLabel.font = AppFont.regular(size: 14)
            emptyLabel.textColor = .secondaryLabel
            bioStackView.addArrangedSubview(emptyLabel)
        }
    }
    
    private func createStatRow(icon: String, title: String, value: String) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = .systemGreen
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = AppFont.regular(size: 14)
        titleLabel.textColor = .secondaryLabel
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = AppFont.semiBold(size: 14)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(iconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            valueLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8),
            
            containerView.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return containerView
    }
}
