import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct TitheWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> TitheWidgetEntry {
        TitheWidgetEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (TitheWidgetEntry) -> Void) {
        let entry = TitheWidgetEntry(date: Date(), data: loadWidgetData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TitheWidgetEntry>) -> Void) {
        let entry = TitheWidgetEntry(date: Date(), data: loadWidgetData())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadWidgetData() -> WidgetDisplayData {
        guard let defaults = UserDefaults(suiteName: "group.com.tithesteward.shared"),
              let data = defaults.data(forKey: "widget_data"),
              let widgetData = try? JSONDecoder().decode(WidgetDisplayData.self, from: data) else {
            return .placeholder
        }
        return widgetData
    }
}

// MARK: - Entry

struct TitheWidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetDisplayData
}

struct WidgetDisplayData: Codable {
    var titheProgressPercent: Double
    var amountGivenThisMonth: Double
    var titheGoal: Double
    var generosityStreak: Int
    var generosityLevel: String
    var todaysVerse: String
    var todaysVerseReference: String
    var debtFreedomPercent: Double

    static var placeholder: WidgetDisplayData {
        WidgetDisplayData(
            titheProgressPercent: 0.65,
            amountGivenThisMonth: 325,
            titheGoal: 500,
            generosityStreak: 12,
            generosityLevel: "Joyful Tither",
            todaysVerse: "Honor the LORD with your wealth...",
            todaysVerseReference: "Proverbs 3:9",
            debtFreedomPercent: 0.42
        )
    }
}

// MARK: - Tithe Progress Widget

struct TitheProgressWidgetView: View {
    var entry: TitheWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidget
        case .systemMedium:
            mediumWidget
        default:
            smallWidget
        }
    }

    var smallWidget: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: entry.data.titheProgressPercent)
                    .stroke(Color("AccentGold"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(entry.data.titheProgressPercent * 100))%")
                    .font(.system(size: 18, weight: .bold))
            }

            Text("Tithe Progress")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("$\(Int(entry.data.amountGivenThisMonth)) / $\(Int(entry.data.titheGoal))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    var mediumWidget: some View {
        HStack(spacing: 16) {
            // Progress circle
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: entry.data.titheProgressPercent)
                        .stroke(Color("AccentGold"), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(entry.data.titheProgressPercent * 100))%")
                        .font(.system(size: 18, weight: .bold))
                }

                Text("Tithe This Month")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("\(entry.data.generosityStreak) month streak")
                        .font(.caption)
                }

                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(Color("AccentGold"))
                        .font(.caption)
                    Text(entry.data.generosityLevel)
                        .font(.caption)
                }

                Divider()

                Text(entry.data.todaysVerse)
                    .font(.caption2.italic())
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Text("— \(entry.data.todaysVerseReference)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Scripture Widget

struct ScriptureWidgetView: View {
    var entry: TitheWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "book.fill")
                .foregroundColor(Color("AccentGold"))

            Text(entry.data.todaysVerse)
                .font(.caption.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)

            Text("— \(entry.data.todaysVerseReference)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Bundle

@main
struct TitheStewardWidgetBundle: WidgetBundle {
    var body: some Widget {
        TitheProgressWidget()
        ScriptureWidget()
    }
}

struct TitheProgressWidget: Widget {
    let kind = "TitheProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TitheWidgetProvider()) { entry in
            TitheProgressWidgetView(entry: entry)
        }
        .configurationDisplayName("Tithe Progress")
        .description("Track your monthly tithe giving at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ScriptureWidget: Widget {
    let kind = "ScriptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TitheWidgetProvider()) { entry in
            ScriptureWidgetView(entry: entry)
        }
        .configurationDisplayName("Stewardship Verse")
        .description("Daily Scripture on money and stewardship.")
        .supportedFamilies([.systemSmall])
    }
}
