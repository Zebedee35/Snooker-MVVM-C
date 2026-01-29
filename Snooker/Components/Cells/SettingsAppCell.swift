//
//  SettingsAppCell.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 31.12.2025.
//

import UIKit

/// Settings cell for app promotion with larger icon and subtitle
final class SettingsAppCell: UITableViewCell {
    
    static let reuseIdentifier = "SettingsAppCell"
    
    // MARK: - UI Components
    
    private let appIconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let appIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let appIconLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.semiBold(size: 16)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.regular(size: 13)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(appIconContainerView)
        appIconContainerView.addSubview(appIconImageView)
        appIconContainerView.addSubview(appIconLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            appIconContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            appIconContainerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            appIconContainerView.widthAnchor.constraint(equalToConstant: 50),
            appIconContainerView.heightAnchor.constraint(equalToConstant: 50),
            
            appIconImageView.topAnchor.constraint(equalTo: appIconContainerView.topAnchor),
            appIconImageView.leadingAnchor.constraint(equalTo: appIconContainerView.leadingAnchor),
            appIconImageView.trailingAnchor.constraint(equalTo: appIconContainerView.trailingAnchor),
            appIconImageView.bottomAnchor.constraint(equalTo: appIconContainerView.bottomAnchor),
            
            appIconLabel.centerXAnchor.constraint(equalTo: appIconContainerView.centerXAnchor),
            appIconLabel.centerYAnchor.constraint(equalTo: appIconContainerView.centerYAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: appIconContainerView.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -40),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor)
        ])
    }
    
    // MARK: - Configure
    
    func configure(with item: SettingsItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        
        // Önce Assets'ten resim var mı kontrol et
        if let iconName = item.appIconName, let image = UIImage(named: iconName) {
            appIconImageView.image = image
            appIconImageView.isHidden = false
            appIconLabel.isHidden = true
        } else {
            // Resim yoksa emoji göster
            appIconLabel.text = item.icon
            appIconLabel.isHidden = false
            appIconImageView.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        appIconLabel.text = nil
        appIconImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }
}
