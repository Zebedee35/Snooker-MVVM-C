//
//  SettingsToggleCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

/// Settings cell with toggle switch
final class SettingsToggleCell: UITableViewCell {
    
    static let reuseIdentifier = "SettingsToggleCell"
    
    // MARK: - Properties
    
    var onToggle: ((Bool) -> Void)?
    
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
    
    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = .systemGreen
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
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
        selectionStyle = .none
        
        contentView.addSubview(iconLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(toggleSwitch)
        
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
            
            toggleSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            toggleSwitch.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    // MARK: - Configure
    
    func configure(with item: SettingsItem) {
        titleLabel.text = item.title
        toggleSwitch.isOn = item.isOn
        
        // Icon handling
        if let icon = item.icon {
            if icon.count == 1 || icon.unicodeScalars.first?.properties.isEmoji == true {
                iconLabel.text = icon
                iconLabel.isHidden = false
                iconImageView.isHidden = true
            } else {
                iconImageView.image = UIImage(systemName: icon)
                iconImageView.tintColor = item.iconColor ?? .label
                iconImageView.isHidden = false
                iconLabel.isHidden = true
            }
        } else {
            iconLabel.isHidden = true
            iconImageView.isHidden = true
        }
    }
    
    // MARK: - Actions
    
    @objc private func toggleChanged() {
        onToggle?(toggleSwitch.isOn)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        iconLabel.text = nil
        iconLabel.isHidden = true
        iconImageView.image = nil
        iconImageView.isHidden = true
        titleLabel.text = nil
        toggleSwitch.isOn = false
        onToggle = nil
    }
}
