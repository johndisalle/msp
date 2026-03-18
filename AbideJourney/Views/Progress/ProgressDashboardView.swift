import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var journeys: [Journey]
    @Query private var prayerSessions: [PrayerSession]
    @State private var viewModel = ProgressViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Journey progress card
                    if let journey = viewModel.journey {
                        JourneyProgressCard(journey: journey)
                    }

                    // Streak card
                    if let streak = viewModel.streakInfo {
                        StreakCard(streakInfo: streak)
                    }

                    // Habit rings
                    HabitRingsCard(
                        prayer: viewModel.prayerRingProgress,
                        word: viewModel.wordRingProgress,
                        obedience: viewModel.obedienceRingProgress,
                        worship: viewModel.worshipRingProgress
                    )

                    // Weekly stats
                    WeeklyStatsCard(
                        prayerMinutes: viewModel.weeklyPrayerMinutes,
                        scriptureCount: viewModel.weeklyScriptureCount,
                        obedienceCount: viewModel.weeklyObedienceCount
                    )

                    // Calendar view
                    if let journey = viewModel.journey {
                        StreakCalendarView(journey: journey)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .onAppear {
                viewModel.loadProgress(from: journeys, sessions: prayerSessions)
            }
        }
    }
}

// MARK: - Journey Progress Card

struct JourneyProgressCard: View {
    let journey: Journey

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(journey.title)
                        .font(.headline)
                    Text("Day \(journey.currentDay) of \(journey.totalDays)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(journey.progress * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(.accent)
            }

            ProgressView(value: journey.progress)
                .tint(.accent)
                .scaleEffect(y: 2)

            HStack {
                Label("\(journey.daysRemaining) days left", systemImage: "calendar")
                Spacer()
                Label(journey.theme.rawValue, systemImage: journey.theme.icon)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Streak Card

struct StreakCard: View {
    let streakInfo: StreakService.StreakInfo

    var body: some View {
        HStack(spacing: 24) {
            StreakStatView(value: streakInfo.currentStreak, label: "Current\nStreak", icon: "flame.fill", color: .orange)
            StreakStatView(value: streakInfo.longestStreak, label: "Longest\nStreak", icon: "trophy.fill", color: .yellow)
            StreakStatView(value: streakInfo.totalDaysCompleted, label: "Total\nDays", icon: "checkmark.seal.fill", color: .green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

struct StreakStatView: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text("\(value)")
                .font(.title.bold())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Habit Rings Card

struct HabitRingsCard: View {
    let prayer: Double
    let word: Double
    let obedience: Double
    let worship: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week's Habits")
                .font(.headline)

            HStack(spacing: 20) {
                HabitRingView(progress: prayer, label: "Prayer", color: .blue, icon: "hands.sparkles.fill")
                HabitRingView(progress: word, label: "Word", color: .green, icon: "text.book.closed.fill")
                HabitRingView(progress: obedience, label: "Obedience", color: .orange, icon: "checkmark.circle.fill")
                HabitRingView(progress: worship, label: "Worship", color: .purple, icon: "music.note")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

struct HabitRingView: View {
    let progress: Double
    let label: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 6)
                    .frame(width: 56, height: 56)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
            }

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Weekly Stats Card

struct WeeklyStatsCard: View {
    let prayerMinutes: Int
    let scriptureCount: Int
    let obedienceCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Summary")
                .font(.headline)

            HStack(spacing: 16) {
                StatItemView(value: "\(prayerMinutes)", unit: "min", label: "Prayer", color: .blue)
                StatItemView(value: "\(scriptureCount)", unit: "days", label: "Scripture", color: .green)
                StatItemView(value: "\(obedienceCount)", unit: "steps", label: "Completed", color: .orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }
}

struct StatItemView: View {
    let value: String
    let unit: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Streak Calendar

struct StreakCalendarView: View {
    let journey: Journey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journey Calendar")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(journey.days.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(dayColor(for: day))
                        .frame(height: 28)
                        .overlay {
                            Text("\(day.dayNumber)")
                                .font(.caption2)
                                .foregroundStyle(day.isCompleted ? .white : .secondary)
                        }
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                    Text("Completed")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.accentColor)
                        .frame(width: 12, height: 12)
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(.systemGray5))
                        .frame(width: 12, height: 12)
                    Text("Upcoming")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
        )
        .padding(.horizontal)
    }

    private func dayColor(for day: JourneyDay) -> Color {
        if day.isCompleted {
            return .green
        } else if day.isUnlocked {
            return .accentColor
        } else {
            return Color(.systemGray5)
        }
    }
}

#Preview {
    ProgressDashboardView()
        .modelContainer(for: Journey.self, inMemory: true)
}
