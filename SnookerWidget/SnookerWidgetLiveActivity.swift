//
//  SnookerWidgetLiveActivity.swift
//  SnookerWidget
//
//  Created by Tayfun Susamcioglu on 5.06.2026.
//
//  SwiftUI UI for the Lock Screen / Banner presentation and the Dynamic Island.
//  Uses the shared MatchLiveActivityAttributes (also in the App target).
//

import ActivityKit
import WidgetKit
import SwiftUI

struct SnookerWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: MatchLiveActivityAttributes.self) { context in
            // MARK: Lock Screen / Banner (expanded, full-width)
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
                .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // MARK: Expanded (long-press) presentation
                DynamicIslandExpandedRegion(.leading) {
                    PlayerColumn(
                        flag: context.attributes.homeFlag,
                        name: context.attributes.homeName,
                        score: context.state.homeScore,
                        isAtTable: context.state.atTable == "home"
                    )
                }
                DynamicIslandExpandedRegion(.trailing) {
                    PlayerColumn(
                        flag: context.attributes.awayFlag,
                        name: context.attributes.awayName,
                        score: context.state.awayScore,
                        isAtTable: context.state.atTable == "away"
                    )
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("\(context.state.homeScore) - \(context.state.awayScore)")
                        .font(.headline.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        StatusPill(status: context.state.status)
                        Spacer()
                        Text(context.attributes.tournamentName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                        Spacer()
                        Text(context.state.round)
                            .font(.caption2.weight(.semibold))
                    }
                }
            } compactLeading: {
                // Tiny — left of the island
                Text(context.attributes.homeFlag)
            } compactTrailing: {
                // Tiny — right of the island: the live score
                Text("\(context.state.homeScore)-\(context.state.awayScore)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
            } minimal: {
                // When multiple activities are active
                Text("\(context.state.homeScore)-\(context.state.awayScore)")
                    .font(.caption2.weight(.bold))
                    .monospacedDigit()
            }
            .widgetURL(URL(string: "snooker://match/\(context.attributes.matchId)"))
            .keylineTint(.green)
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<MatchLiveActivityAttributes>

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                StatusPill(status: context.state.status)
                Spacer()
                Text(context.attributes.tournamentName)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                Spacer()
                Text(context.state.round)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }

            HStack(alignment: .center) {
                PlayerColumn(
                    flag: context.attributes.homeFlag,
                    name: context.attributes.homeName,
                    score: context.state.homeScore,
                    isAtTable: context.state.atTable == "home"
                )
                Text("\(context.state.homeScore) - \(context.state.awayScore)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                PlayerColumn(
                    flag: context.attributes.awayFlag,
                    name: context.attributes.awayName,
                    score: context.state.awayScore,
                    isAtTable: context.state.atTable == "away"
                )
            }

            if let brk = context.state.currentBreak, brk > 0,
               context.state.status.lowercased() == "live" {
                Text("Break: \(brk)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.green)
            }
        }
        .padding()
    }
}

// MARK: - Reusable pieces

private struct PlayerColumn: View {
    let flag: String
    let name: String
    let score: Int
    let isAtTable: Bool

    var body: some View {
        VStack(spacing: 3) {
            Text(flag).font(.title3)
            Text(name)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if isAtTable {
                Circle().fill(.green).frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct StatusPill: View {
    let status: String

    private var color: Color {
        switch status.lowercased() {
        case "live":      return .red
        case "break":     return .orange
        default:          return .gray   // Completed / Finished
        }
    }

    var body: some View {
        Text(status.uppercased())
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(color))
    }
}

// MARK: - Preview

extension MatchLiveActivityAttributes {
    fileprivate static var preview: MatchLiveActivityAttributes {
        MatchLiveActivityAttributes(
            matchId: "preview",
            tournamentName: "World Championship 2025",
            homeName: "R. O'Sullivan",
            homeFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            awayName: "J. Trump",
            awayFlag: "🏴󠁧󠁢󠁥󠁮󠁧󠁿",
            framesToWin: 18
        )
    }
}

extension MatchLiveActivityAttributes.ContentState {
    fileprivate static var live: MatchLiveActivityAttributes.ContentState {
        .init(homeScore: 12, awayScore: 9, status: "Live", round: "Final", currentBreak: 47, atTable: "home")
    }
    fileprivate static var onBreak: MatchLiveActivityAttributes.ContentState {
        .init(homeScore: 12, awayScore: 10, status: "Break", round: "Final", currentBreak: nil, atTable: nil)
    }
}

#Preview("Lock Screen", as: .content, using: MatchLiveActivityAttributes.preview) {
    SnookerWidgetLiveActivity()
} contentStates: {
    MatchLiveActivityAttributes.ContentState.live
    MatchLiveActivityAttributes.ContentState.onBreak
}
