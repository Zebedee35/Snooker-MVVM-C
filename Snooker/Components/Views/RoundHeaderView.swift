//
//  RoundHeaderView.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 1.12.2025.
//

import UIKit

/// Round section header view - Sadece round adını gösterir
final class RoundHeaderView: UICollectionReusableView {
    
    static let identifier = "RoundHeaderView"
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let roundNameLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: 18)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        addSubview(containerView)
        containerView.addSubview(roundNameLabel)
        containerView.addSubview(separatorView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            roundNameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            roundNameLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            roundNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            roundNameLabel.bottomAnchor.constraint(equalTo: separatorView.topAnchor, constant: -8),
            
            separatorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            separatorView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            separatorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            separatorView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
    }
    
    // MARK: - Configuration
    
    func configure(roundName: String) {
        roundNameLabel.text = roundName
    }
    
    // MARK: - Reuse
    
    override func prepareForReuse() {
        super.prepareForReuse()
        roundNameLabel.text = nil
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct RoundHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RoundHeaderViewPreviewWrapper(roundName: "Final")
                .frame(height: 50)
                .previewDisplayName("Final - Light")
            
            RoundHeaderViewPreviewWrapper(roundName: "Semi Final")
                .frame(height: 50)
                .preferredColorScheme(.dark)
                .previewDisplayName("Semi Final - Dark")
            
            RoundHeaderViewPreviewWrapper(roundName: "Round 1")
                .frame(height: 50)
                .previewDisplayName("Round 1")
            
            RoundHeaderViewPreviewWrapper(roundName: "Quarter Final")
                .frame(height: 50)
                .previewDisplayName("Quarter Final")
        }
        .previewLayout(.sizeThatFits)
    }
}

@available(iOS 13.0, *)
private struct RoundHeaderViewPreviewWrapper: UIViewRepresentable {
    let roundName: String
    
    func makeUIView(context: Context) -> RoundHeaderView {
        let view = RoundHeaderView(frame: CGRect(x: 0, y: 0, width: 375, height: 50))
        view.configure(roundName: roundName)
        return view
    }
    
    func updateUIView(_ uiView: RoundHeaderView, context: Context) {}
}
#endif
