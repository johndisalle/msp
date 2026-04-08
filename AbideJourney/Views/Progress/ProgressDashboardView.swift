import SwiftUI
import SwiftData

struct ProgressDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var journeys: [Journey]
    @Query private var profiles: [UserProfile]
    @Query private var journalEntries: [JournalEntry]
    @State private var viewModel = ProgressViewModel()
    @State private var showingPremiumSheet = false

    private var isPremium: Bool { profiles.first?.isPremium ?? false }

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

                    // Achievements
                    NavigationLink {
                        AchievementsView()
                    } label: {
                        AchievementsSummaryCard(journeys: journeys, journalCount: journalEntries.count)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Year in Review
                    NavigationLink {
                        FaithWrappedView()
                            .navigationBarBackButtonHidden(false)
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(red: 0.15, green: 0.20, blue: 0.38), Color(red: 0.30, green: 0.15, blue: 0.45)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                Image(systemName: "sparkles")
                                    .font(.body)
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(Calendar.current.component(.year, from: Date())) Faith Wrapped")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AJTheme.primaryText)
                                Text("Your year in review — shareable!")
                                    .font(.caption)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }

                            Spacer()

                            Text("NEW")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(.red))

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AJTheme.cardBackground)
                                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    // Habit rings
                    HabitRingsCard(
                        prayer: viewModel.prayerRingProgress,
                        word: viewModel.wordRingProgress,
                        obedience: viewModel.obedienceRingProgress,
                        worship: viewModel.worshipRingProgress
                    )

                    // Weekly stats
                    WeeklyStatsCard(
                        prayerDays: viewModel.weeklyPrayerCount,
                        scriptureCount: viewModel.weeklyScriptureCount,
                        obedienceCount: viewModel.weeklyObedienceCount
                    )

                    // Calendar view
                    if let journey = viewModel.journey {
                        StreakCalendarView(journey: journey)
                    }

                    // Premium feature cards on Progress tab
                    if isPremium {
                        // Faith Map
                        NavigationLink {
                            FaithMapView()
                        } label: {
                            PremiumProgressCard(
                                icon: "map.fill",
                                color: .teal,
                                title: "Faith Map",
                                subtitle: "See your spiritual growth visualized over time"
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        // Faith Report
                        NavigationLink {
                            FaithReportView()
                        } label: {
                            PremiumProgressCard(
                                icon: "sparkles.rectangle.stack.fill",
                                color: .indigo,
                                title: "Annual Faith Report",
                                subtitle: "A beautiful summary of your year with God"
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)

                        // Accountability
                        NavigationLink {
                            AccountabilityView()
                        } label: {
                            PremiumProgressCard(
                                icon: "person.2.fill",
                                color: .green,
                                title: "Accountability Partners",
                                subtitle: "Invite a friend to walk alongside you"
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    } else {
                        // Faith Map link (free users)
                        NavigationLink {
                            FaithMapView()
                        } label: {
                            HStack {
                                Image(systemName: "map.fill")
                                    .foregroundStyle(AJTheme.sage)
                                Text("View Faith Map")
                                    .font(.subheadline.bold())
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AJTheme.sage.opacity(0.08))
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    // Premium journey themes teaser (only for free users, shown after 7+ days)
                    if !isPremium, let journey = viewModel.journey, journey.currentDay >= 7 {
                        PremiumThemesTeaser {
                            showingPremiumSheet = true
                        }
                    }
                }
                .padding(.vertical)
            }
            .ajScreenBackground()
            .navigationTitle("Progress")
            .onAppear {
                viewModel.loadProgress(from: journeys)
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
        }
    }
}

// MARK: - Premium Themes Teaser

struct PremiumThemesTeaser: View {
    let onTap: () -> Void

    private let themes: [(icon: String, name: String, color: Color)] = [
        ("heart.circle.fill", "Anxiety", .red),
        ("drop.fill", "Grief", .blue),
        ("figure.stand", "Leadership", .orange),
        ("flame.fill", "Hearing God", .purple),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's Next?")
                .font(AJTheme.subheadlineFont)

            Text("Keep growing with deep-dive journeys designed for where life has you right now.")
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .lineSpacing(2)

            HStack(spacing: 10) {
                ForEach(themes, id: \.name) { theme in
                    VStack(spacing: 6) {
                        Image(systemName: theme.icon)
                            .font(.title3)
                            .foregroundStyle(theme.color)
                            .accessibilityHidden(true)

                        Text(theme.name)
                            .font(.caption2)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(theme.color.opacity(0.08))
                    )
                }
            }

            Button {
                onTap()
            } label: {
                HStack {
                    Text("Explore Premium")
                        .font(.subheadline.bold())
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(AJTheme.sage.opacity(0.1))
                .foregroundStyle(AJTheme.sage)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .ajCard()
        .padding(.horizontal)
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
                        .font(AJTheme.subheadlineFont)
                    Text("Day \(journey.currentDay) of \(journey.totalDays)")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                Spacer()
                Text("\(Int(journey.progress * 100))%")
                    .font(.title2.bold())
                    .foregroundStyle(AJTheme.gold)
            }

            ProgressView(value: journey.progress)
                .tint(AJTheme.sage)
                .scaleEffect(y: 2)

            HStack {
                Label("\(journey.daysRemaining) days left", systemImage: "calendar")
                Spacer()
                Label(journey.theme.rawValue, systemImage: journey.theme.icon)
            }
            .font(AJTheme.captionFont)
            .foregroundStyle(AJTheme.secondaryText)
        }
        .ajCard()
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
        .ajCard()
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
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label.replacingOccurrences(of: "\n", with: " ")), \(value)")
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
                .font(AJTheme.subheadlineFont)

            HStack(spacing: 20) {
                HabitRingView(progress: prayer, label: "Prayer", color: .blue, icon: "hands.sparkles.fill")
                HabitRingView(progress: word, label: "Word", color: .green, icon: "text.book.closed.fill")
                HabitRingView(progress: obedience, label: "Obedience", color: .orange, icon: "checkmark.circle.fill")
                HabitRingView(progress: worship, label: "Worship", color: .purple, icon: "music.note")
            }
        }
        .ajCard()
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
                .foregroundStyle(AJTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(Int(progress * 100)) percent")
    }
}

// MARK: - Weekly Stats Card

struct WeeklyStatsCard: View {
    let prayerDays: Int
    let scriptureCount: Int
    let obedienceCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Summary")
                .font(AJTheme.subheadlineFont)

            HStack(spacing: 16) {
                StatItemView(value: "\(prayerDays)", unit: "days", label: "Prayer", color: .blue)
                StatItemView(value: "\(scriptureCount)", unit: "days", label: "Scripture", color: .green)
                StatItemView(value: "\(obedienceCount)", unit: "steps", label: "Completed", color: .orange)
            }
        }
        .ajCard()
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
                    .foregroundStyle(AJTheme.secondaryText)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(AJTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), \(value) \(unit)")
    }
}

// MARK: - Streak Calendar

struct StreakCalendarView: View {
    let journey: Journey

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journey Calendar")
                .font(AJTheme.subheadlineFont)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach((journey.days ?? []).sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(dayColor(for: day))
                        .frame(height: 28)
                        .overlay {
                            Text("\(day.dayNumber)")
                                .font(.caption2)
                                .foregroundStyle(day.isCompleted ? .white : AJTheme.secondaryText)
                        }
                        .accessibilityLabel("Day \(day.dayNumber), \(day.isCompleted ? "completed" : day.isUnlocked ? "current" : "upcoming")")
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AJTheme.success)
                        .frame(width: 12, height: 12)
                    Text("Completed")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AJTheme.sage)
                        .frame(width: 12, height: 12)
                    Text("Today")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AJTheme.cream)
                        .frame(width: 12, height: 12)
                    Text("Upcoming")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.secondaryText)
                }
            }
        }
        .ajCard()
        .padding(.horizontal)
    }

    private func dayColor(for day: JourneyDay) -> Color {
        if day.isCompleted {
            return AJTheme.success
        } else if day.isUnlocked {
            return AJTheme.sage
        } else {
            return AJTheme.cream
        }
    }
}

// MARK: - Premium Progress Card

struct PremiumProgressCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.08))
        )
    }
}

// MARK: - Achievements Summary Card

struct AchievementsSummaryCard: View {
    let journeys: [Journey]
    let journalCount: Int

    private var earnedCount: Int {
        AchievementService.shared.earnedBadgeIDs.count
    }

    private var recentBadges: [AchievementBadge] {
        let earned = AchievementService.shared.earnedBadgeIDs
        return BadgeCatalog.all.filter { earned.contains($0.id) }.suffix(3).reversed()
    }

    private var unseenCount: Int {
        AchievementService.shared.unseenBadgeIDs.count
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("Achievements")
                    .font(AJTheme.subheadlineFont)
                Spacer()
                if unseenCount > 0 {
                    Text("\(unseenCount) new!")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(.red))
                }
                HStack(spacing: 2) {
                    Text("\(earnedCount)/\(BadgeCatalog.all.count)")
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            if recentBadges.isEmpty {
                Text("Complete days to start earning badges!")
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 12) {
                    ForEach(recentBadges) { badge in
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(badge.color.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: badge.icon)
                                    .font(.body)
                                    .foregroundStyle(badge.color)
                            }
                            Text(badge.name)
                                .font(.caption2)
                                .foregroundStyle(AJTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                    }

                    if recentBadges.count < 3 {
                        ForEach(0..<(3 - recentBadges.count), id: \.self) { _ in
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.08))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "questionmark")
                                        .font(.body)
                                        .foregroundStyle(.gray.opacity(0.3))
                                }
                                Text("???")
                                    .font(.caption2)
                                    .foregroundStyle(.gray.opacity(0.3))
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .onAppear {
            AchievementService.shared.evaluate(journeys: journeys, journalEntryCount: journalCount)
        }
    }
}

#Preview {
    ProgressDashboardView()
        .modelContainer(for: Journey.self, inMemory: true)
}
