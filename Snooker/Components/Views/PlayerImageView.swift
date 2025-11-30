//
//  PlayerImageView.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 5.11.2025.
//

import UIKit

enum PlayerImageSize {
  case small, medium, large, extraLarge
  
  var dimension: CGFloat {
    switch self {
    case .small: return 50
    case .medium: return 90
    case .large: return 120
    case .extraLarge: return 150
    }
  }
  
  var borderWidth: CGFloat {
    switch self {
    case .small: return 2
    case .medium: return 2.5
    case .large: return 3
    case .extraLarge: return 3.5
    }
  }
}

final class PlayerImageView: UIView {
  
  // MARK: - Properties
  
  private let imageView: UIImageView = {
    let imageView = UIImageView()
    imageView.contentMode = .scaleAspectFill
    imageView.clipsToBounds = true
    imageView.backgroundColor = .systemGray5
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
  
  private let activityIndicator: UIActivityIndicatorView = {
    let indicator = UIActivityIndicatorView(style: .medium)
    indicator.hidesWhenStopped = true
    indicator.translatesAutoresizingMaskIntoConstraints = false
    return indicator
  }()
  
  private let placeholderImageView: UIImageView = {
    let imageView = UIImageView()
    imageView.image = UIImage(systemName: "person.circle.fill")
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .systemGray3
    imageView.translatesAutoresizingMaskIntoConstraints = false
    return imageView
  }()
  
  private var size: PlayerImageSize
  private var imageURL: URL?
  private var imageTask: Task<Void, Never>?
  
  // Image cache
  private static let imageCache = NSCache<NSString, UIImage>()
  
  // MARK: - Initialization
  
  init(size: PlayerImageSize = .medium) {
    self.size = size
    super.init(frame: .zero)
    setupView()
  }
  
  required init?(coder: NSCoder) {
    self.size = .medium
    super.init(coder: coder)
    setupView()
  }
  
  // MARK: - Setup
  
  private func setupView() {
    translatesAutoresizingMaskIntoConstraints = false
    backgroundColor = .clear
    
    // Add border and shadow for better appearance
    layer.borderColor = UIColor.systemGray4.cgColor
    layer.borderWidth = size.borderWidth
    layer.shadowColor = UIColor.black.cgColor
    layer.shadowOpacity = 0.1
    layer.shadowOffset = CGSize(width: 0, height: 2)
    layer.shadowRadius = 4
    layer.masksToBounds = false // Shadow için gerekli
    
    addSubview(imageView)
    addSubview(placeholderImageView)
    addSubview(activityIndicator)
    
    // Width ve height constraint'lerini eşit öncelikle ekle
    let widthConstraint = widthAnchor.constraint(equalToConstant: size.dimension)
    let heightConstraint = heightAnchor.constraint(equalToConstant: size.dimension)
    
    // Her ikisine de high priority ver (tam kare olması için)
    widthConstraint.priority = .required
    heightConstraint.priority = .required
    
    NSLayoutConstraint.activate([
      // Container size - Square olmalı
      widthConstraint,
      heightConstraint,
      
      // ImageView - tam oturacak şekilde
      imageView.topAnchor.constraint(equalTo: topAnchor),
      imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
      imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
      
      // Placeholder
      placeholderImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
      placeholderImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
      placeholderImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.6),
      placeholderImageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.6),
      
      // Activity Indicator
      activityIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: centerYAnchor)
    ])
  }
  
  override var intrinsicContentSize: CGSize {
    // Her zaman square boyut döndür
    return CGSize(width: size.dimension, height: size.dimension)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    // Her layout'ta circle şeklini garanti et
    let radius = min(bounds.width, bounds.height) / 2
    layer.cornerRadius = radius
    imageView.layer.cornerRadius = radius
    
    // ImageView'un masksToBounds'unu true yap
    imageView.layer.masksToBounds = true
  }
  
  // Frame değişimlerinde de güncelle
  override var frame: CGRect {
    didSet {
      if frame.size != oldValue.size {
        setNeedsLayout()
      }
    }
  }
  
  override var bounds: CGRect {
    didSet {
      if bounds.size != oldValue.size {
        setNeedsLayout()
      }
    }
  }
  
  // MARK: - Public Methods
  
  func configure(with urlString: String?) {
    // Cancel previous task
    imageTask?.cancel()
    
    // Reset state
    imageView.image = nil
    placeholderImageView.isHidden = false
    
    guard let urlString = urlString,
          let url = URL(string: urlString) else {
      return
    }
    
    self.imageURL = url
    
    // Check cache first
    let cacheKey = urlString as NSString
    if let cachedImage = Self.imageCache.object(forKey: cacheKey) {
      setImage(cachedImage)
      return
    }
    
    // Load from network
    imageTask = Task { @MainActor in
      await loadImage(from: url, cacheKey: cacheKey)
    }
  }
  
  // MARK: - Private Methods
  
  @MainActor
  private func loadImage(from url: URL, cacheKey: NSString) async {
    activityIndicator.startAnimating()
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      
      guard let image = UIImage(data: data) else {
        activityIndicator.stopAnimating()
        return
      }
      
      // Cache the image
      Self.imageCache.setObject(image, forKey: cacheKey)
      
      // Only set if URL hasn't changed
      if self.imageURL == url {
        self.setImage(image)
      }
    } catch {
      // Handle error silently - image will show placeholder
      activityIndicator.stopAnimating()
    }
  }
  
  @MainActor
  private func setImage(_ image: UIImage) {
    activityIndicator.stopAnimating()
    placeholderImageView.isHidden = true
    
    UIView.transition(with: imageView,
                      duration: 0.3,
                      options: .transitionCrossDissolve) {
      self.imageView.image = image
    }
  }
  
  // MARK: - Cleanup
  
  deinit {
    imageTask?.cancel()
  }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct PlayerImageView_Previews: PreviewProvider {
  static var previews: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Title
        Text("PlayerImageView Sizes")
          .font(.title2)
          .bold()
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal)
        
        // All sizes in one view
        VStack(spacing: 20) {
          // Small
          PreviewRow(
            title: "Small (60x60)",
            urlString: "https://35coders.com/common/snooker/img/ronnie-osullivan.jpg",
            size: .small
          )
          
          Divider()
          
          // Medium
          PreviewRow(
            title: "Medium (90x90)",
            urlString: "https://35coders.com/common/snooker/img/judd-trump.jpg",
            size: .medium
          )
          
          Divider()
          
          // Large
          PreviewRow(
            title: "Large (120x120)",
            urlString: "https://35coders.com/common/snooker/img/mselby.jpg",
            size: .large
          )
          
          Divider()
          
          // Extra Large
          PreviewRow(
            title: "Extra Large (150x150)",
            urlString: "https://35coders.com/common/snooker/img/mark-williams.jpg",
            size: .extraLarge
          )
          
          Divider()
          
          // Placeholder
          PreviewRow(
            title: "Placeholder (No URL)",
            urlString: nil,
            size: .medium
          )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
        
        Spacer()
      }
      .padding(.vertical)
    }
    .previewLayout(.sizeThatFits)
    .frame(width: 375, height: 700)
    .previewDisplayName("All Sizes")
  }
}

// MARK: - Preview Helpers

@available(iOS 13.0, *)
private struct PreviewRow: View {
  let title: String
  let urlString: String?
  let size: PlayerImageSize
  
  var body: some View {
    HStack(alignment: .center, spacing: 16) {
      PlayerImageViewWrapper(urlString: urlString, size: size)
        .frame(width: size.dimension, height: size.dimension)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.headline)
        
        if let urlString = urlString {
          Text(urlString.components(separatedBy: "/").last ?? "")
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
        } else {
          Text("No image URL")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      
      Spacer()
    }
    .frame(height: max(size.dimension + 16, 60)) // Minimum height ve dinamik height
  }
}

@available(iOS 13.0, *)
struct PlayerImageViewWrapper: UIViewRepresentable {
  let urlString: String?
  let size: PlayerImageSize
  
  func makeUIView(context: Context) -> PlayerImageView {
    let view = PlayerImageView(size: size)
    view.configure(with: urlString)
    return view
  }
  
  func updateUIView(_ uiView: PlayerImageView, context: Context) {
    uiView.configure(with: urlString)
  }
}

#endif

