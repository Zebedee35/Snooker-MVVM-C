//
//  LiveActivityManager.swift
//  Snooker
//
//  Owns the lifecycle of match Live Activities and registers their push tokens
//  with Supabase so the backend can update/end them remotely via APNs.
//
//  Flow:
//   1. User taps "Follow" on a live match  ->  start(for:)
//   2. We observe the activity's pushTokenUpdates and upsert it to
//      `live_activities` (match_id, activity_id, push_token).
//   3. Backend pushes content-state updates to that token (see Edge Function).
//   4. Match ends  ->  backend pushes event:"end", OR app calls end(matchId:).
//
//  Created for the Live Activities feature.
//

import Foundation
import ActivityKit
import Supabase

@available(iOS 16.2, *)   // ActivityContent + request(attributes:content:pushType:) are 16.2+
final class LiveActivityManager {

    static let shared = LiveActivityManager()
    private init() {}

    /// Keep references so we can update/end them locally if the app is in front.
    private var activities: [String: Activity<MatchLiveActivityAttributes>] = [:]  // keyed by matchId

    // MARK: - Public API

    var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    /// True if we are already showing a Live Activity for this match.
    func isActive(matchId: String) -> Bool {
        if activities[matchId] != nil { return true }
        return Activity<MatchLiveActivityAttributes>.activities
            .contains { $0.attributes.matchId == matchId }
    }

    /// Start a Live Activity for a match the user wants to follow.
    @discardableResult
    func start(for match: LiveScoreCellPresentation, framesToWin: Int) -> Bool {
        guard areActivitiesEnabled else {
            print("[LiveActivity] Activities disabled in Settings")
            return false
        }
        guard !isActive(matchId: match.matchId) else {
            print("[LiveActivity] Already active for \(match.matchId)")
            return false
        }

        let attributes = MatchLiveActivityAttributes(
            matchId: match.matchId,
            tournamentName: match.round,            // pass the real tournament name if you have it here
            homeName: match.homePlayerShortName,
            homeFlag: match.homePlayerFlag ?? "",
            awayName: match.awayPlayerShortName,
            awayFlag: match.awayPlayerFlag ?? "",
            framesToWin: framesToWin
        )

        let initialState = MatchLiveActivityAttributes.ContentState(
            homeScore: match.homePlayerScore,
            awayScore: match.awayPlayerScore,
            status: match.matchStatus,
            round: match.round,
            currentBreak: nil,
            atTable: nil
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: staleDate()),
                pushType: .token   // ⬅️ ask iOS for a remote push token
            )
            activities[match.matchId] = activity
            print("[LiveActivity] Started \(activity.id) for match \(match.matchId)")

            observePushToken(for: activity, matchId: match.matchId)
            observeState(for: activity, matchId: match.matchId)
            return true
        } catch {
            print("[LiveActivity] Failed to start: \(error)")
            return false
        }
    }

    /// Locally update an activity (used only when the app is in the foreground for
    /// instant feedback; the backend push is the source of truth otherwise).
    func updateLocally(matchId: String, state: MatchLiveActivityAttributes.ContentState) {
        guard let activity = activities[matchId] else { return }
        Task {
            await activity.update(.init(state: state, staleDate: staleDate()))
        }
    }

    /// End the activity for a match (call when the user un-follows; the backend
    /// will end it automatically when the match completes).
    func end(matchId: String, finalState: MatchLiveActivityAttributes.ContentState? = nil) {
        guard let activity = activities[matchId] else { return }
        Task {
            let content: ActivityContent<MatchLiveActivityAttributes.ContentState>?
            if let finalState {
                content = .init(state: finalState, staleDate: nil)
            } else {
                content = nil
            }
            await activity.end(content, dismissalPolicy: .after(.now + 60 * 60))  // auto-dismiss after 1h
            activities[matchId] = nil
            await deactivateOnServer(activityId: activity.id)
            print("[LiveActivity] Ended \(activity.id)")
        }
    }

    func endAll() {
        Task {
            for activity in Activity<MatchLiveActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            activities.removeAll()
        }
    }

    /// Call once on launch to (a) re-attach to activities that survived a relaunch
    /// and (b) start observing the push-to-start token (iOS 17.2+).
    func bootstrap() {
        for activity in Activity<MatchLiveActivityAttributes>.activities {
            activities[activity.attributes.matchId] = activity
            observePushToken(for: activity, matchId: activity.attributes.matchId)
            observeState(for: activity, matchId: activity.attributes.matchId)
        }
        observePushToStartToken()
    }

    // MARK: - Token observation

    private func observePushToken(for activity: Activity<MatchLiveActivityAttributes>, matchId: String) {
        Task {
            for await tokenData in activity.pushTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[LiveActivity] push token for \(matchId): \(token.prefix(12))…")
                await registerOnServer(activityId: activity.id, matchId: matchId, token: token)
            }
        }
    }

    /// iOS 17.2+: lets the SERVER start a Live Activity without the app running.
    private func observePushToStartToken() {
        guard #available(iOS 17.2, *) else { return }
        Task {
            for await tokenData in Activity<MatchLiveActivityAttributes>.pushToStartTokenUpdates {
                let token = tokenData.map { String(format: "%02x", $0) }.joined()
                print("[LiveActivity] push-to-start token: \(token.prefix(12))…")
                await registerPushToStartToken(token)
            }
        }
    }

    private func observeState(for activity: Activity<MatchLiveActivityAttributes>, matchId: String) {
        Task {
            for await state in activity.activityStateUpdates {
                if state == .ended || state == .dismissed {
                    activities[matchId] = nil
                    await deactivateOnServer(activityId: activity.id)
                }
            }
        }
    }

    // MARK: - Supabase persistence

    private func registerOnServer(activityId: String, matchId: String, token: String) async {
        do {
            try await SupabaseAPI.client
                .from("live_activities")
                .upsert([
                    "activity_id": activityId,
                    "match_id": matchId,
                    "push_token": token,
                    "status": "active",
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ], onConflict: "activity_id")
                .execute()
        } catch {
            print("[LiveActivity] registerOnServer failed: \(error)")
        }
    }

    private func deactivateOnServer(activityId: String) async {
        do {
            try await SupabaseAPI.client
                .from("live_activities")
                .update(["status": "ended"])
                .eq("activity_id", value: activityId)
                .execute()
        } catch {
            print("[LiveActivity] deactivateOnServer failed: \(error)")
        }
    }

    private func registerPushToStartToken(_ token: String) async {
        // Stored alongside the device token so the backend can remotely START activities.
        guard let deviceToken = UserDefaults.standard.string(forKey: "device_token") else { return }
        do {
            try await SupabaseAPI.client
                .from("device_tokens")
                .update(["pts_token": token])
                .eq("token", value: deviceToken)
                .execute()
        } catch {
            print("[LiveActivity] registerPushToStartToken failed: \(error)")
        }
    }

    // MARK: - Helpers

    /// After this date the activity is shown as "stale" (dimmed). Keeps the UI
    /// honest if pushes stop arriving. 30 min is generous for a snooker frame.
    private func staleDate() -> Date { Date().addingTimeInterval(30 * 60) }
}
