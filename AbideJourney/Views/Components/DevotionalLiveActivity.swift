import SwiftUI
import WidgetKit
import ActivityKit

struct DevotionalLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DevotionalActivityAttributes.self) { context in
            // Lock Screen / Banner presentation
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(.black.opacity(0.8))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Day \(context.state.dayNumber)")
                            .font(.headline.bold())
                        Text(context.state.focusArea)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 3)
                            .frame(width: 44, height: 44)
                        Circle()
                            .trim(from: 0, to: context.state.progress)
                            .stroke(.accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(context.state.progress * 100))%")
                            .font(.caption2.bold())
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    if context.state.isPrayerTimerActive {
                        HStack(spacing: 8) {
                            Image(systemName: "hands.sparkles.fill")
                                .foregroundStyle(.yellow)
                            Text(formatTime(context.state.prayerElapsedSeconds))
                                .font(.system(.title3, design: .monospaced).bold())
                            Text("/ \(formatTime(context.state.prayerTargetSeconds))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(""\(context.state.verseSnippet)"")
                            .font(.caption)
                            .italic()
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                        Text("— \(context.state.verseReference)")
                            .font(.caption2.bold())
                            .foregroundStyle(.accent)
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                HStack(spacing: 4) {
                    Image(systemName: "book.fill")
                        .foregroundStyle(.accent)
                    Text("Day \(context.state.dayNumber)")
                        .font(.caption2.bold())
                }
            } compactTrailing: {
                if context.state.isPrayerTimerActive {
                    Text(formatTime(context.state.prayerElapsedSeconds))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.accent)
                } else {
                    Text("\(Int(context.state.progress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.accent)
                }
            } minimal: {
                Image(systemName: "book.fill")
                    .foregroundStyle(.accent)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Lock Screen View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DevotionalActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.journeyTitle)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    Text("Day \(context.state.dayNumber) of \(context.state.totalDays)")
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

                Spacer()

                // Progress ring
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.2), lineWidth: 4)
                        .frame(width: 48, height: 48)
                    Circle()
                        .trim(from: 0, to: context.state.progress)
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 48, height: 48)
                        .rotationEffect(.degrees(-90))
                    Text("\(context.state.dayNumber)")
                        .font(.system(.body, design: .rounded).bold())
                        .foregroundStyle(.white)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.15))
                        .frame(height: 4)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * context.state.progress, height: 4)
                }
            }
            .frame(height: 4)

            // Verse
            VStack(spacing: 4) {
                Text(""\(context.state.verseSnippet)"")
                    .font(.subheadline)
                    .italic()
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text("— \(context.state.verseReference)")
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }

            // Prayer timer (if active)
            if context.state.isPrayerTimerActive {
                HStack {
                    Image(systemName: "hands.sparkles.fill")
                        .foregroundStyle(.yellow)

                    Text("Praying")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))

                    Spacer()

                    Text(formatTime(context.state.prayerElapsedSeconds))
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundStyle(.white)

                    Text("/ \(formatTime(context.state.prayerTargetSeconds))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Focus area badge
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: focusIcon(context.state.focusArea))
                        .font(.caption2)
                    Text(context.state.focusArea)
                        .font(.caption2.bold())
                }
                .foregroundStyle(.white.opacity(0.7))

                Spacer()

                Text("Tap to open")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(16)
    }

    private func formatTime(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func focusIcon(_ area: String) -> String {
        switch area {
        case "Prayer": return "hands.sparkles.fill"
        case "Scripture": return "text.book.closed.fill"
        case "Obedience": return "checkmark.circle.fill"
        case "Worship": return "music.note"
        case "Community": return "person.3.fill"
        case "Evangelism": return "megaphone.fill"
        case "Service": return "hand.raised.fill"
        default: return "book.fill"
        }
    }
}
