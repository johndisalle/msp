import SwiftUI
import SwiftData

struct WatchHomeView: View {
    @State private var sync = WatchSyncReceiver.shared
    @State private var showingPrayerTimer = false
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            if sync.hasData {
                TabView(selection: $selectedTab) {
                    // Tab 1: Today's Overview
                    WatchTodayTab(sync: sync, showingPrayerTimer: $showingPrayerTimer)
                        .tag(0)

                    // Tab 2: Scripture Detail
                    WatchScriptureTab(sync: sync)
                        .tag(1)

                    // Tab 3: Devotional
                    WatchDevotionalTab(sync: sync)
                        .tag(2)

                    // Tab 4: Stats
                    WatchStatsTab(sync: sync)
                        .tag(3)
                }
                .tabViewStyle(.verticalPage)
                .navigationTitle("Abide")
                .sheet(isPresented: $showingPrayerTimer) {
                    WatchPrayerTimerView()
                }
            } else {
                ContentUnavailableView {
                    Label("No Journey", systemImage: "book.closed")
                } description: {
                    Text("Start a journey on your iPhone to begin.")
                }
            }
        }
    }
}

// MARK: - Today Tab

struct WatchTodayTab: View {
    let sync: WatchSyncReceiver
    @Binding var showingPrayerTimer: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Day progress
                VStack(alignment: .leading, spacing: 8) {
                    Text("Day \(sync.dayNumber)/\(sync.totalDays)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(sync.focusArea)
                        .font(.headline)

                    ProgressView(value: sync.progress)
                        .tint(.accent)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.darkGray).opacity(0.3))
                )

                // Quick verse preview
                VStack(alignment: .leading, spacing: 4) {
                    Text(sync.scriptureReference)
                        .font(.caption2.bold())
                        .foregroundStyle(.accent)
                    Text(sync.scriptureText)
                        .font(.caption)
                        .lineLimit(2)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.accentColor.opacity(0.1))
                )

                // Action buttons
                HStack(spacing: 8) {
                    Button {
                        showingPrayerTimer = true
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "hands.sparkles.fill")
                                .font(.title3)
                            Text("Pray")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.accent)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Scripture Tab

struct WatchScriptureTab: View {
    let sync: WatchSyncReceiver

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "text.book.closed.fill")
                        .foregroundStyle(.accent)
                    Text("Scripture")
                        .font(.caption.bold())
                }

                Text(sync.scriptureReference)
                    .font(.caption.bold())
                    .foregroundStyle(.accent)

                Text("\u{201C}\(sync.scriptureText)\u{201D}")
                    .font(.caption)
                    .italic()
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
        }
    }
}

// MARK: - Devotional Tab

struct WatchDevotionalTab: View {
    let sync: WatchSyncReceiver

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .foregroundStyle(.orange)
                    Text("Devotional")
                        .font(.caption.bold())
                }

                Text(sync.devotionalTitle)
                    .font(.caption.bold())

                Text(sync.devotionalText)
                    .font(.caption2)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Reflection prompt
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "pencil.and.outline")
                            .foregroundStyle(.purple)
                            .font(.caption2)
                        Text("Reflect")
                            .font(.caption2.bold())
                    }
                    Text(sync.reflectionPrompt)
                        .font(.caption2)
                        .italic()
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - Stats Tab

struct WatchStatsTab: View {
    let sync: WatchSyncReceiver

    private var completedDays: Int {
        sync.currentDay
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Progress")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                // Journey progress ring
                ZStack {
                    Circle()
                        .stroke(Color(.darkGray), lineWidth: 6)
                        .frame(width: 80, height: 80)
                    Circle()
                        .trim(from: 0, to: sync.progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(completedDays)")
                            .font(.title3.bold())
                        Text("of \(sync.totalDays)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Streak stats
                HStack(spacing: 16) {
                    WatchStatItem(
                        value: "\(sync.currentStreak)",
                        label: "Streak",
                        icon: "flame.fill",
                        color: .orange
                    )
                    WatchStatItem(
                        value: "\(sync.longestStreak)",
                        label: "Best",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }
            }
            .padding()
        }
    }
}

struct WatchStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Watch Prayer Timer

struct WatchPrayerTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var timerService = PrayerTimerService()
    @State private var selectedMinutes = 5
    @State private var hasStarted = false

    private let presetMinutes = [3, 5, 10, 15]

    var body: some View {
        VStack(spacing: 12) {
            if !hasStarted && !timerService.isRunning {
                // Duration picker
                Text("Prayer Timer")
                    .font(.caption.bold())

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(presetMinutes, id: \.self) { minutes in
                            Button {
                                selectedMinutes = minutes
                            } label: {
                                Text("\(minutes)m")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.bordered)
                            .tint(selectedMinutes == minutes ? .accent : .gray)
                        }
                    }
                }

                Button {
                    hasStarted = true
                    timerService.targetMinutes = selectedMinutes
                    timerService.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            } else {
                // Timer circle
                ZStack {
                    Circle()
                        .stroke(Color(.darkGray), lineWidth: 4)

                    Circle()
                        .trim(from: 0, to: timerService.progress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.5), value: timerService.progress)

                    VStack(spacing: 2) {
                        Text(timerService.isRunning ? timerService.formattedRemaining : timerService.formattedTime)
                            .font(.system(.title3, design: .monospaced))
                            .bold()

                        Text(timerService.isRunning ? "remaining" : "elapsed")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Controls
                HStack(spacing: 16) {
                    if !timerService.isRunning && timerService.elapsedSeconds > 0 {
                        Button {
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
        }
        .navigationTitle("Prayer")
    }
}

#Preview {
    WatchHomeView()
}
