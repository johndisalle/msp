import SwiftUI
import SwiftData

struct WatchHomeView: View {
    @Query(filter: #Predicate<Journey> { $0.isActive }) private var journeys: [Journey]
    @State private var showingPrayerTimer = false

    private var activeJourney: Journey? { journeys.first }
    private var currentDay: JourneyDay? {
        activeJourney?.days
            .sorted { $0.dayNumber < $1.dayNumber }
            .first { !$0.isCompleted && $0.isUnlocked }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    if let journey = activeJourney, let day = currentDay {
                        // Today's focus
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Day \(day.dayNumber)/\(journey.totalDays)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)

                            Text(day.focusArea.rawValue)
                                .font(.headline)

                            ProgressView(value: journey.progress)
                                .tint(.accent)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )

                        // Today's verse
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.scriptureReference)
                                .font(.caption2.bold())
                                .foregroundStyle(.accent)
                            Text(day.scriptureText)
                                .font(.caption)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.accentColor.opacity(0.1))
                        )

                        // Prayer timer button
                        Button {
                            showingPrayerTimer = true
                        } label: {
                            Label("Pray", systemImage: "timer")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Text("No active journey")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Abide")
            .sheet(isPresented: $showingPrayerTimer) {
                WatchPrayerTimerView()
            }
        }
    }
}

// MARK: - Watch Prayer Timer

struct WatchPrayerTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var timerService = PrayerTimerService()
    @State private var selectedMinutes = 5

    var body: some View {
        VStack(spacing: 16) {
            // Timer circle
            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 4)

                Circle()
                    .trim(from: 0, to: timerService.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(timerService.isRunning ? timerService.formattedRemaining : "\(selectedMinutes):00")
                        .font(.system(.title3, design: .monospaced))
                        .bold()

                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            // Controls
            HStack(spacing: 16) {
                if timerService.elapsedSeconds > 0 && !timerService.isRunning {
                    Button {
                        // Save session
                        let session = PrayerSession(duration: timerService.elapsedSeconds, type: .devotional)
                        modelContext.insert(session)
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .tint(.green)
                }

                Button {
                    if timerService.isRunning {
                        timerService.pause()
                    } else {
                        timerService.targetMinutes = selectedMinutes
                        timerService.start()
                    }
                } label: {
                    Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                }
                .tint(.accent)
            }
        }
        .navigationTitle("Prayer")
    }
}

#Preview {
    WatchHomeView()
        .modelContainer(for: Journey.self, inMemory: true)
}
