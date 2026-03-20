// WatchStreakComplication.swift
// FaithForgeWatch
//
// WidgetKit complication for Apple Watch showing streak count.

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct StreakTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: Date(), streak: 7)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: Date(), streak: 7))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        // In production, read from shared UserDefaults / App Group
        let entry = StreakEntry(date: Date(), streak: UserDefaults.standard.integer(forKey: "currentStreak"))
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
}

// MARK: - Complication View

struct StreakComplicationView: View {
    var entry: StreakEntry

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: entry.streak > 0 ? "flame.fill" : "flame")
                .font(.title3)
                .foregroundStyle(entry.streak > 0 ? .orange : .gray)

            Text("\(entry.streak)")
                .font(.headline.bold())
                .foregroundStyle(.primary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition

struct FaithForgeWatchComplication: Widget {
    let kind: String = "FaithForgeStreak"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakComplicationView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Your current FaithForge streak.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}

#Preview(as: .accessoryCircular) {
    FaithForgeWatchComplication()
} timeline: {
    StreakEntry(date: Date(), streak: 12)
    StreakEntry(date: Date(), streak: 0)
}
