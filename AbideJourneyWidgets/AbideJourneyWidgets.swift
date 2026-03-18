import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Provider

struct AbideJourneyProvider: TimelineProvider {
    func placeholder(in context: Context) -> AbideJourneyEntry {
        AbideJourneyEntry(
            date: Date(),
            dayNumber: 1,
            totalDays: 40,
            verseReference: "Psalm 119:105",
            verseSnippet: "Your word is a lamp for my feet, a light on my path.",
            focusArea: "Scripture",
            progress: 0.025
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (AbideJourneyEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AbideJourneyEntry>) -> Void) {
        // In production, fetch from SwiftData/shared container
        let entry = placeholder(in: context)
        let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct AbideJourneyEntry: TimelineEntry {
    let date: Date
    let dayNumber: Int
    let totalDays: Int
    let verseReference: String
    let verseSnippet: String
    let focusArea: String
    let progress: Double
}

// MARK: - Large Widget (Verse + Progress)

struct AbideJourneyLargeWidget: Widget {
    let kind = "AbideJourneyLargeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AbideJourneyProvider()) { entry in
            LargeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Verse")
        .description("See today's Scripture passage and journey progress.")
        .supportedFamilies([.systemLarge, .systemMedium])
    }
}

struct LargeWidgetView: View {
    let entry: AbideJourneyEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "book.circle.fill")
                    .foregroundStyle(.accent)
                Text("Day \(entry.dayNumber)/\(entry.totalDays)")
                    .font(.caption.bold())
                Spacer()
                Text(entry.focusArea)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            ProgressView(value: entry.progress)
                .tint(.accent)

            // Verse
            VStack(alignment: .leading, spacing: 6) {
                Text(""\(entry.verseSnippet)"")
                    .font(.body)
                    .italic()
                    .lineLimit(4)

                Text("— \(entry.verseReference)")
                    .font(.caption.bold())
                    .foregroundStyle(.accent)
            }

            Spacer()

            // Action hint
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.caption2)
                Text("Tap to open today's devotional")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
        }
        .padding()
    }
}

// MARK: - Small Widget (Quick Pray Button)

struct AbideJourneySmallWidget: Widget {
    let kind = "AbideJourneySmallWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AbideJourneyProvider()) { entry in
            SmallWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Pray")
        .description("One-tap access to prayer timer and today's focus.")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetView: View {
    let entry: AbideJourneyEntry

    var body: some View {
        VStack(spacing: 8) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                Text("\(entry.dayNumber)")
                    .font(.system(.body, design: .rounded).bold())
            }

            Text(entry.focusArea)
                .font(.caption2.bold())

            // Pray button appearance
            HStack(spacing: 4) {
                Image(systemName: "hands.sparkles.fill")
                    .font(.caption2)
                Text("Pray")
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.accentColor.opacity(0.2))
            .clipShape(Capsule())
        }
    }
}

// MARK: - Widget Bundle

@main
struct AbideJourneyWidgetBundle: WidgetBundle {
    var body: some Widget {
        AbideJourneyLargeWidget()
        AbideJourneySmallWidget()
    }
}

#Preview("Large", as: .systemLarge) {
    AbideJourneyLargeWidget()
} timeline: {
    AbideJourneyEntry(
        date: Date(),
        dayNumber: 12,
        totalDays: 40,
        verseReference: "Philippians 4:6-7",
        verseSnippet: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.",
        focusArea: "Prayer",
        progress: 0.3
    )
}

#Preview("Small", as: .systemSmall) {
    AbideJourneySmallWidget()
} timeline: {
    AbideJourneyEntry(
        date: Date(),
        dayNumber: 12,
        totalDays: 40,
        verseReference: "Philippians 4:6-7",
        verseSnippet: "Do not be anxious about anything...",
        focusArea: "Prayer",
        progress: 0.3
    )
}
