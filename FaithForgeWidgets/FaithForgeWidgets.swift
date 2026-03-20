// FaithForgeWidgets.swift
// FaithForgeWidgets
//
// Home screen widget: today's top quest + streak counter.

import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct FaithForgeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FaithForgeEntry {
        FaithForgeEntry(
            date: Date(),
            streak: 7,
            topQuestTitle: "Morning Prayer",
            topQuestCategory: "Prayer",
            topQuestXP: 30,
            completedCount: 2,
            totalCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (FaithForgeEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FaithForgeEntry>) -> Void) {
        // Read from shared UserDefaults (App Group) in production.
        // For MVP, show placeholder data.
        let defaults = UserDefaults.standard
        let entry = FaithForgeEntry(
            date: Date(),
            streak: defaults.integer(forKey: "currentStreak"),
            topQuestTitle: defaults.string(forKey: "topQuestTitle") ?? "Read a Psalm",
            topQuestCategory: defaults.string(forKey: "topQuestCategory") ?? "The Word",
            topQuestXP: defaults.integer(forKey: "topQuestXP") == 0 ? 30 : defaults.integer(forKey: "topQuestXP"),
            completedCount: defaults.integer(forKey: "completedQuestCount"),
            totalCount: defaults.integer(forKey: "totalQuestCount") == 0 ? 5 : defaults.integer(forKey: "totalQuestCount")
        )

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct FaithForgeEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let topQuestTitle: String
    let topQuestCategory: String
    let topQuestXP: Int
    let completedCount: Int
    let totalCount: Int
}

// MARK: - Widget Views

struct FaithForgeWidgetSmall: View {
    let entry: FaithForgeEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: streak
            HStack {
                Image(systemName: "cross.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text("FaithForge")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)

                Spacer()

                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                    Text("\(entry.streak)")
                        .font(.caption.bold())
                }
            }

            Spacer()

            // Top Quest
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.topQuestCategory)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(entry.topQuestTitle)
                    .font(.subheadline.bold())
                    .lineLimit(2)

                Text("+\(entry.topQuestXP) XP")
                    .font(.caption2.bold())
                    .foregroundStyle(.yellow)
            }

            // Progress
            HStack(spacing: 4) {
                ForEach(0..<entry.totalCount, id: \.self) { i in
                    Circle()
                        .fill(i < entry.completedCount ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                Spacer()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct FaithForgeWidgetMedium: View {
    let entry: FaithForgeEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: Streak + Progress
            VStack(spacing: 8) {
                VStack(spacing: 2) {
                    Image(systemName: entry.streak > 0 ? "flame.fill" : "flame")
                        .font(.title)
                        .foregroundStyle(entry.streak > 0 ? .orange : .gray)

                    Text("\(entry.streak)")
                        .font(.title2.bold())

                    Text("day streak")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text("\(entry.completedCount)/\(entry.totalCount) quests")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()

            // Right: Top Quest
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "cross.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("Next Quest")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.topQuestCategory)
                        .font(.caption2)
                        .foregroundStyle(.blue)

                    Text(entry.topQuestTitle)
                        .font(.subheadline.bold())
                        .lineLimit(2)

                    Text("+\(entry.topQuestXP) XP")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition

struct FaithForgeWidget: Widget {
    let kind: String = "FaithForgeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FaithForgeTimelineProvider()) { entry in
            switch WidgetFamily.systemSmall {
            default:
                FaithForgeWidgetSmall(entry: entry)
            }
        }
        .configurationDisplayName("FaithForge")
        .description("Track your daily quests and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct FaithForgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        FaithForgeWidget()
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    FaithForgeWidget()
} timeline: {
    FaithForgeEntry(date: Date(), streak: 12, topQuestTitle: "Morning Prayer", topQuestCategory: "Prayer", topQuestXP: 30, completedCount: 2, totalCount: 5)
}

#Preview("Medium", as: .systemMedium) {
    FaithForgeWidget()
} timeline: {
    FaithForgeEntry(date: Date(), streak: 12, topQuestTitle: "Read a Psalm", topQuestCategory: "The Word", topQuestXP: 30, completedCount: 3, totalCount: 5)
}
