//
//  AnnouncementManager.swift
//  Snooker
//
//  Created by GitHub Copilot on 22.04.2026.
//

import UIKit

final class AnnouncementManager {

    static let shared = AnnouncementManager()

    private enum UserDefaultsKeys {
        static let dismissedOneTimeAnnouncementIDs = "dismissed_one_time_announcement_ids"
    }

    private weak var window: UIWindow?
    private var bannerView: FloatingAnnouncementView?
    private var bannerTopConstraint: NSLayoutConstraint?
    private var bannerBottomConstraint: NSLayoutConstraint?

    private var announcementQueue: [AppAnnouncementDTO] = []
    private var currentAnnouncement: AppAnnouncementDTO?
    private var fetchTask: Task<Void, Never>?

    private init() {}

    func start(in window: UIWindow) {
        self.window = window
        refreshAnnouncements()
    }

    func refreshAnnouncements() {
        fetchTask?.cancel()

        fetchTask = Task { [weak self] in
            guard let self else { return }

            do {
                let announcements = try await SupabaseAPI.fetchActiveAnnouncements()
                await MainActor.run {
                    self.updateQueue(with: announcements)
                }
            } catch {
                print("[AnnouncementManager] Failed to fetch announcements: \(error)")
            }
        }
    }

    @MainActor
    private func updateQueue(with announcements: [AppAnnouncementDTO]) {
        let visible = filterVisibleAnnouncements(announcements)
        announcementQueue = visible

        if let currentAnnouncement,
           let nextAnnouncement = visible.first,
           currentAnnouncement.id == nextAnnouncement.id {
            return
        }

        presentTopAnnouncement()
    }

    @MainActor
    private func filterVisibleAnnouncements(_ announcements: [AppAnnouncementDTO]) -> [AppAnnouncementDTO] {
        let dismissedOneTimeAnnouncements = dismissedOneTimeAnnouncementIDs()
        let now = Date()

        return announcements
            .filter { $0.isActive }
            .filter { $0.isContentValid }
            .filter { !$0.isExpired(at: now) }
            .filter { announcement in
                guard announcement.displayMode == .oneTime else { return true }
                return !dismissedOneTimeAnnouncements.contains(announcement.id)
            }
            .sorted { left, right in
                if left.displayRank != right.displayRank {
                    return left.displayRank > right.displayRank
                }

                let leftDate = left.createdDate ?? .distantPast
                let rightDate = right.createdDate ?? .distantPast
                return leftDate > rightDate
            }
    }

    @MainActor
    private func presentTopAnnouncement() {
        guard let announcement = announcementQueue.first else {
            currentAnnouncement = nil
            hideBanner(animated: true)
            return
        }

        currentAnnouncement = announcement

        guard let window else { return }

        let bannerView = self.bannerView ?? FloatingAnnouncementView()
        bannerView.configure(with: announcement)
        bannerView.onCloseTapped = { [weak self] in
            Task { @MainActor in
                self?.dismissCurrentAnnouncement()
            }
        }

        if bannerView.superview == nil {
            window.addSubview(bannerView)
            let safeArea = window.safeAreaLayoutGuide

            let preferredWidthConstraint = bannerView.widthAnchor.constraint(equalTo: safeArea.widthAnchor, constant: -24)
            preferredWidthConstraint.priority = .defaultHigh

            NSLayoutConstraint.activate([
                bannerView.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor),
                bannerView.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: 12),
                bannerView.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor, constant: -12),
                preferredWidthConstraint,
                bannerView.widthAnchor.constraint(lessThanOrEqualToConstant: 560)
            ])
        }

        bannerTopConstraint?.isActive = false
        bannerBottomConstraint?.isActive = false

        switch announcement.placementZone {
        case .top:
            bannerTopConstraint = bannerView.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: 10)
            bannerTopConstraint?.isActive = true
        case .bottom:
            bannerBottomConstraint = bannerView.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -10)
            bannerBottomConstraint?.isActive = true
        }

        window.layoutIfNeeded()

        self.bannerView = bannerView

        bannerView.alpha = 0
        bannerView.transform = CGAffineTransform(translationX: 0, y: announcement.placementZone == .top ? -20 : 20)

        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            bannerView.alpha = 1
            bannerView.transform = .identity
        }
    }

    @MainActor
    private func dismissCurrentAnnouncement() {
        guard let currentAnnouncement else { return }

        if currentAnnouncement.displayMode == .oneTime {
            saveDismissedOneTimeAnnouncementID(currentAnnouncement.id)
        }

        announcementQueue.removeAll { $0.id == currentAnnouncement.id }
        self.currentAnnouncement = nil

        hideBanner(animated: true) { [weak self] in
            Task { @MainActor in
                self?.presentTopAnnouncement()
            }
        }
    }

    @MainActor
    private func hideBanner(animated: Bool, completion: (() -> Void)? = nil) {
        guard let bannerView else {
            completion?()
            return
        }

        let dismissTransform: CGAffineTransform
        if currentAnnouncement?.placementZone == .top {
            dismissTransform = CGAffineTransform(translationX: 0, y: -16)
        } else {
            dismissTransform = CGAffineTransform(translationX: 0, y: 16)
        }

        let animations = {
            bannerView.alpha = 0
            bannerView.transform = dismissTransform
        }

        let cleanup = {
            bannerView.removeFromSuperview()
            bannerView.transform = .identity
            self.bannerTopConstraint = nil
            self.bannerBottomConstraint = nil
            self.bannerView = nil
            completion?()
        }

        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseIn, .allowUserInteraction], animations: animations) { _ in
                cleanup()
            }
        } else {
            animations()
            cleanup()
        }
    }

    private func dismissedOneTimeAnnouncementIDs() -> Set<String> {
        let ids = UserDefaults.standard.stringArray(forKey: UserDefaultsKeys.dismissedOneTimeAnnouncementIDs) ?? []
        return Set(ids)
    }

    private func saveDismissedOneTimeAnnouncementID(_ id: String) {
        var ids = dismissedOneTimeAnnouncementIDs()
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: UserDefaultsKeys.dismissedOneTimeAnnouncementIDs)
    }
}
