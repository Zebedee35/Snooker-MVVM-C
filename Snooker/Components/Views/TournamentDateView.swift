//
//  TournamentDateView.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 26.12.2025.
//

import UIKit

/// Apple Takvim ikonu tarzında tarih görünümü
/// Üstte ay (kırmızı), altta tarih aralığı gösterir
final class TournamentDateView: UIView {
    
    // MARK: - Constants
    
    private enum Constants {
        static let viewHeight: CGFloat = 60
        static let viewWidth: CGFloat = 60
        static let cornerRadius: CGFloat = 10
        static let monthFontSize: CGFloat = 12
        static let dayFontSize: CGFloat = 18
        static let monthAreaHeight: CGFloat = 20
        static let activeMonthColor: UIColor = .systemRed
        static let activeDayColor: UIColor = .label
        static let inactiveMonthColor: UIColor = .systemGray3
        static let inactiveDayColor: UIColor = .systemGray
    }
    
    // MARK: - UI Components
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = Constants.cornerRadius
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let monthContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = Constants.activeMonthColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let monthLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: Constants.monthFontSize)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dayContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = AppFont.bold(size: Constants.dayFontSize)
        label.textColor = Constants.activeDayColor
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private var isPast: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        registerTraitChanges()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(monthContainerView)
        containerView.addSubview(dayContainerView)
        monthContainerView.addSubview(monthLabel)
        dayContainerView.addSubview(dayLabel)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: Constants.viewWidth),
            containerView.heightAnchor.constraint(equalToConstant: Constants.viewHeight),
            
            // Month Container (top area)
            monthContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            monthContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            monthContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            monthContainerView.heightAnchor.constraint(equalToConstant: Constants.monthAreaHeight),
            
            // Month Label
            monthLabel.centerXAnchor.constraint(equalTo: monthContainerView.centerXAnchor),
            monthLabel.centerYAnchor.constraint(equalTo: monthContainerView.centerYAnchor),
            
            // Day Container (bottom area)
            dayContainerView.topAnchor.constraint(equalTo: monthContainerView.bottomAnchor),
            dayContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            dayContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            dayContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            // Day Label
            dayLabel.centerXAnchor.constraint(equalTo: dayContainerView.centerXAnchor),
            dayLabel.centerYAnchor.constraint(equalTo: dayContainerView.centerYAnchor),
            dayLabel.leadingAnchor.constraint(greaterThanOrEqualTo: dayContainerView.leadingAnchor, constant: 2),
            dayLabel.trailingAnchor.constraint(lessThanOrEqualTo: dayContainerView.trailingAnchor, constant: -2),
        ])
    }
    
    // MARK: - Configuration
    
    /// Tek tarih için yapılandırma (sadece bir gün)
    func configure(date: Date, isPast: Bool = false) {
        self.isPast = isPast
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        // Ay
        formatter.dateFormat = "MMM"
        monthLabel.text = formatter.string(from: date).uppercased()
        
        // Gün
        formatter.dateFormat = "d"
        dayLabel.text = formatter.string(from: date)
    }
    
    /// Tarih aralığı için yapılandırma (başlangıç - bitiş)
    func configure(startDate: Date, endDate: Date, isPast: Bool = false) {
        self.isPast = isPast
        
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        let calendar = Calendar.current
        let startMonth = calendar.component(.month, from: startDate)
        let endMonth = calendar.component(.month, from: endDate)
        let startDay = calendar.component(.day, from: startDate)
        let endDay = calendar.component(.day, from: endDate)
        
        // Ay
        formatter.dateFormat = "MMM"
        if startMonth == endMonth {
            // Aynı ay
            monthLabel.text = formatter.string(from: startDate).uppercased()
        } else {
            // Farklı aylar
            let startMonthStr = formatter.string(from: startDate).prefix(3).uppercased()
            let endMonthStr = formatter.string(from: endDate).prefix(3).uppercased()
            monthLabel.text = "\(startMonthStr)-\(endMonthStr)"
        }
        
        // Günler
        if startDay == endDay && startMonth == endMonth {
            dayLabel.text = "\(startDay)"
        } else {
            dayLabel.text = "\(startDay)-\(endDay)"
        }
    }
    
    /// String tarihler için yapılandırma
    func configure(startDateString: String?, endDateString: String?) {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        
        // Alternatif format dene
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var startDate: Date?
        var endDate: Date?
        
        if let startStr = startDateString {
            startDate = isoFormatter.date(from: startStr) ?? dateFormatter.date(from: startStr)
        }
        
        if let endStr = endDateString {
            endDate = isoFormatter.date(from: endStr) ?? dateFormatter.date(from: endStr)
        }
        
        guard let start = startDate else {
            monthLabel.text = "TBD"
            dayLabel.text = "-"
            return
        }
        
        // Geçmiş mi kontrol et
        let isPast = (endDate ?? start) < Date()
        
        if let end = endDate {
            configure(startDate: start, endDate: end, isPast: isPast)
        } else {
            configure(date: start, isPast: isPast)
        }
    }
    
    // MARK: - Appearance
    
    private func updateAppearance() {
        if isPast {
            // Geçmiş tarih - gri tonları
            monthContainerView.backgroundColor = Constants.inactiveMonthColor
            monthLabel.textColor = .white
            dayLabel.textColor = Constants.inactiveDayColor
            containerView.layer.borderColor = UIColor.systemGray4.cgColor
            dayContainerView.backgroundColor = .systemGray6
        } else {
            // Aktif/gelecek tarih
            monthContainerView.backgroundColor = Constants.activeMonthColor
            monthLabel.textColor = .white
            dayLabel.textColor = Constants.activeDayColor
            containerView.layer.borderColor = UIColor.separator.cgColor
            dayContainerView.backgroundColor = .systemBackground
        }
    }
    
    private func registerTraitChanges() {
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.containerView.layer.borderColor = self.isPast ? UIColor.systemGray4.cgColor : UIColor.separator.cgColor
            }
        }
    }
    
    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges instead")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0) {
            containerView.layer.borderColor = isPast ? UIColor.systemGray4.cgColor : UIColor.separator.cgColor
        }
    }
}

// MARK: - Previews

#if DEBUG
import SwiftUI

@available(iOS 13.0, *)
struct TournamentDateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Aktif turnuva - tek gün
            TournamentDateViewPreviewWrapper(
                startDate: Date(),
                endDate: nil,
                isPast: false
            )
            .frame(width: 60, height: 60)
            .previewDisplayName("Single Day - Active")
            
            // Aktif turnuva - tarih aralığı (aynı ay)
            TournamentDateViewPreviewWrapper(
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                isPast: false
            )
            .frame(width: 60, height: 60)
            .previewDisplayName("Date Range - Same Month")
            
            // Aktif turnuva - tarih aralığı (farklı ay)
            TournamentDateViewPreviewWrapper(
                startDate: Date(),
                endDate: Date().addingTimeInterval(45 * 24 * 60 * 60),
                isPast: false
            )
            .frame(width: 60, height: 60)
            .previewDisplayName("Date Range - Different Month")
            
            // Geçmiş turnuva
            TournamentDateViewPreviewWrapper(
                startDate: Date().addingTimeInterval(-30 * 24 * 60 * 60),
                endDate: Date().addingTimeInterval(-23 * 24 * 60 * 60),
                isPast: true
            )
            .frame(width: 60, height: 60)
            .previewDisplayName("Past Tournament")
            
            // Dark mode
            TournamentDateViewPreviewWrapper(
                startDate: Date(),
                endDate: Date().addingTimeInterval(7 * 24 * 60 * 60),
                isPast: false
            )
            .frame(width: 60, height: 60)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}

@available(iOS 13.0, *)
private struct TournamentDateViewPreviewWrapper: UIViewRepresentable {
    let startDate: Date
    let endDate: Date?
    let isPast: Bool
    
    func makeUIView(context: Context) -> TournamentDateView {
        let view = TournamentDateView()
        if let end = endDate {
            view.configure(startDate: startDate, endDate: end, isPast: isPast)
        } else {
            view.configure(date: startDate, isPast: isPast)
        }
        return view
    }
    
    func updateUIView(_ uiView: TournamentDateView, context: Context) {}
}
#endif
