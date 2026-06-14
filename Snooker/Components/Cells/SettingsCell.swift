//
//  SettingsCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

/// Standard settings cell with icon, title, and optional accessory
final class SettingsCell: UITableViewCell {
    
    static let reuseIdentifier = "SettingsCell"
    
    // MARK: - UI Components
    
    private let iconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = .systemGreen
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // MARK: - Init
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        contentView.addSubview(iconLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 28),
            
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: checkmarkImageView.leadingAnchor, constant: -8),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    
    // MARK: - Configure
    
    func configure(with item: SettingsItem) {
        titleLabel.text = item.title
        titleLabel.textColor = item.isDestructive ? .systemRed : .label

        // Icon handling
        if let icon = item.icon {
            if icon.count == 1 || icon.unicodeScalars.first?.properties.isEmoji == true {
                // Emoji
                iconLabel.text = icon
                iconLabel.isHidden = false
                iconImageView.isHidden = true
            } else {
                // SF Symbol
                iconImageView.image = UIImage(systemName: icon)
                iconImageView.tintColor = item.iconColor ?? .label
                iconImageView.isHidden = false
                iconLabel.isHidden = true
            }
        } else {
            iconLabel.isHidden = true
            iconImageView.isHidden = true
        }
        
        // Accessory type based on item type
        switch item.type {
        case .navigation:
            accessoryType = .disclosureIndicator
            checkmarkImageView.isHidden = true
        case .radio:
            accessoryType = .none
            checkmarkImageView.isHidden = !item.isSelected
        case .action:
            accessoryType = item.isDestructive ? .none : .disclosureIndicator
            checkmarkImageView.isHidden = true
        default:
            accessoryType = .none
            checkmarkImageView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconLabel.text = nil
        iconLabel.isHidden = true
        iconImageView.image = nil
        iconImageView.isHidden = true
        titleLabel.text = nil
        checkmarkImageView.isHidden = true
        accessoryType = .none
    }
}
