import SwiftUI
import SwiftData

// MARK: - Faith Wrapped (Year in Review)

struct FaithWrappedView: View {
    @Query private var journeys: [Journey]
    @Query private var journalEntries: [JournalEntry]
    @State private var currentSlide = 0
    @State private var appeared = false
    @State private var showingShareSheet = false

    private var stats: WrappedStats {
        WrappedStats.compute(journeys: journeys, journalEntries: journalEntries)
    }

    private var slides: [WrappedSlide] {
        var s: [WrappedSlide] = []

        s.append(.intro(year: stats.year))

        if stats.totalDaysCompleted > 0 {
            s.append(.bigNumber(value: "\(stats.totalDaysCompleted)", label: "days spent\nwith God", color: .blue, icon: "calendar.badge.checkmark"))
        }

        if stats.longestStreak > 0 {
            s.append(.bigNumber(value: "\(stats.longestStreak)", label: "day streak\nyour longest yet", color: .orange, icon: "flame.fill"))
        }

        if stats.journeysCompleted > 0 {
            s.append(.bigNumber(value: "\(stats.journeysCompleted)", label: "journey\(stats.journeysCompleted == 1 ? "" : "s")\ncompleted", color: .green, icon: "flag.checkered"))
        }

        if stats.journalCount > 0 {
            s.append(.bigNumber(value: "\(stats.journalCount)", label: "journal\nreflections", color: .purple, icon: "pencil.and.outline"))
        }

        if stats.prayerCount > 0 {
            s.append(.bigNumber(value: "\(stats.prayerCount)", label: "prayers\nlifted up", color: .indigo, icon: "hands.sparkles.fill"))
        }

        if stats.versesMemorized > 0 {
            s.append(.bigNumber(value: "\(stats.versesMemorized)", label: "verses\nmemorized", color: .teal, icon: "brain.head.profile"))
        }

        if stats.badgesEarned > 0 {
            s.append(.bigNumber(value: "\(stats.badgesEarned)", label: "badges\nearned", color: .yellow, icon: "trophy.fill"))
        }

        if let topTheme = stats.topTheme {
            s.append(.topTheme(theme: topTheme))
        }

        s.append(.summary(stats: stats))
        s.append(.closing(year: stats.year))

        return s
    }

    var body: some View {
        ZStack {
            // Background
            slideBackground(for: currentSlide)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentSlide)

            VStack {
                // Progress dots
                HStack(spacing: 4) {
                    ForEach(0..<slides.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentSlide ? Color.white : Color.white.opacity(0.3))
                            .frame(width: i == currentSlide ? 20 : 6, height: 4)
                            .animation(.easeInOut(duration: 0.3), value: currentSlide)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 24)

                Spacer()

                // Slide content
                Group {
                    switch slides[currentSlide] {
                    case .intro(let year):
                        introSlide(year: year)
                    case .bigNumber(let value, let label, _, let icon):
                        bigNumberSlide(value: value, label: label, icon: icon)
                    case .topTheme(let theme):
                        topThemeSlide(theme: theme)
                    case .summary(let stats):
                        summarySlide(stats: stats)
                    case .closing(let year):
                        closingSlide(year: year)
                    }
                }
                .id(currentSlide)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Navigation
                HStack {
                    if currentSlide > 0 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentSlide -= 1
                            }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    Spacer()

                    if currentSlide < slides.count - 1 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                currentSlide += 1
                            }
                        } label: {
                            HStack {
                                Text("Next")
                                    .font(.headline)
                                Image(systemName: "chevron.right")
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    } else {
                        Button {
                            shareWrapped()
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share My Year")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.white.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    if value.translation.width < -50 && currentSlide < slides.count - 1 {
                        withAnimation(.easeInOut(duration: 0.4)) { currentSlide += 1 }
                    } else if value.translation.width > 50 && currentSlide > 0 {
                        withAnimation(.easeInOut(duration: 0.4)) { currentSlide -= 1 }
                    }
                }
        )
        .sheet(isPresented: $showingShareSheet) {
            if let image = renderSummaryImage() {
                ShareSheet(items: [image, "My \(stats.year) Faith Journey on Abide Journey #FaithWrapped #AbideJourney"])
            }
        }
    }

    // MARK: - Slide Views

    private func introSlide(year: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "cross.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white.opacity(0.9))

            Text(verbatim: "Your \(year)\nFaith Journey")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("Let's look back at how\nGod moved in your life")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func bigNumberSlide(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.8))

            Text(value)
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(label)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func topThemeSlide(theme: String) -> some View {
        VStack(spacing: 24) {
            Text("Your Top Journey")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))

            Text(theme)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("This is the theme God kept\nbringing you back to")
                .font(.body)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }

    private func summarySlide(stats: WrappedStats) -> some View {
        VStack(spacing: 16) {
            Text(verbatim: "\(stats.year) Recap")
                .font(.title2.bold())
                .foregroundStyle(.white)

            VStack(spacing: 12) {
                summaryRow(icon: "calendar", label: "Days with God", value: "\(stats.totalDaysCompleted)")
                summaryRow(icon: "flame.fill", label: "Longest Streak", value: "\(stats.longestStreak) days")
                summaryRow(icon: "flag.checkered", label: "Journeys", value: "\(stats.journeysCompleted)")
                summaryRow(icon: "pencil", label: "Journal Entries", value: "\(stats.journalCount)")
                summaryRow(icon: "hands.sparkles", label: "Prayers", value: "\(stats.prayerCount)")
                summaryRow(icon: "trophy.fill", label: "Badges", value: "\(stats.badgesEarned)")
            }
            .padding()
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .padding(.horizontal, 24)
    }

    private func summaryRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(.white)
        }
    }

    private func closingSlide(year: Int) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 50))
                .foregroundStyle(.white.opacity(0.8))

            Text("God isn't done\nwith you yet")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text("\"He who began a good work in you will\ncarry it on to completion.\"")
                .font(.body.italic())
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Text("Philippians 1:6")
                .font(.subheadline.bold())
                .foregroundStyle(.white.opacity(0.5))

            Text(verbatim: "Here's to \(year + 1)")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 8)
        }
    }

    // MARK: - Background

    private func slideBackground(for index: Int) -> some View {
        let colors: [[Color]] = [
            [Color(red: 0.15, green: 0.20, blue: 0.35), Color(red: 0.08, green: 0.10, blue: 0.25)],
            [Color(red: 0.12, green: 0.30, blue: 0.55), Color(red: 0.08, green: 0.15, blue: 0.35)],
            [Color(red: 0.55, green: 0.30, blue: 0.15), Color(red: 0.35, green: 0.15, blue: 0.10)],
            [Color(red: 0.15, green: 0.40, blue: 0.30), Color(red: 0.08, green: 0.25, blue: 0.18)],
            [Color(red: 0.30, green: 0.15, blue: 0.45), Color(red: 0.15, green: 0.08, blue: 0.30)],
            [Color(red: 0.20, green: 0.25, blue: 0.50), Color(red: 0.10, green: 0.12, blue: 0.30)],
            [Color(red: 0.15, green: 0.35, blue: 0.40), Color(red: 0.08, green: 0.20, blue: 0.25)],
            [Color(red: 0.45, green: 0.25, blue: 0.15), Color(red: 0.30, green: 0.12, blue: 0.08)],
            [Color(red: 0.20, green: 0.15, blue: 0.40), Color(red: 0.12, green: 0.08, blue: 0.25)],
            [Color(red: 0.12, green: 0.25, blue: 0.45), Color(red: 0.06, green: 0.12, blue: 0.30)],
            [Color(red: 0.18, green: 0.22, blue: 0.38), Color(red: 0.08, green: 0.10, blue: 0.22)],
        ]
        let pair = colors[index % colors.count]
        return LinearGradient(colors: pair, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: - Share

    @MainActor
    private func renderSummaryImage() -> UIImage? {
        let renderer = ImageRenderer(content:
            WrappedShareCard(stats: stats)
                .frame(width: 1080, height: 1920)
        )
        renderer.scale = 1.0
        return renderer.uiImage
    }

    private func shareWrapped() {
        showingShareSheet = true
    }
}

// MARK: - Wrapped Stats

struct WrappedStats {
    let year: Int
    let totalDaysCompleted: Int
    let longestStreak: Int
    let journeysCompleted: Int
    let journalCount: Int
    let prayerCount: Int
    let versesMemorized: Int
    let badgesEarned: Int
    let topTheme: String?
    let godMomentsCount: Int

    static func compute(journeys: [Journey], journalEntries: [JournalEntry]) -> WrappedStats {
        let year = Calendar.current.component(.year, from: Date())
        let startOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))!

        let yearJourneys = journeys.filter { $0.startDate >= startOfYear }

        let totalDays = yearJourneys.reduce(0) { sum, j in
            sum + (j.days?.filter { $0.isCompleted }.count ?? 0)
        }

        let completed = yearJourneys.filter { $0.isCompleted }.count
        let streak = yearJourneys.reduce(0) { max($0, StreakService.shared.calculateStreak(for: $1).longestStreak) }

        let yearEntries = journalEntries.filter { $0.createdAt >= startOfYear }

        // Theme frequency
        var themeCount: [String: Int] = [:]
        for j in yearJourneys {
            themeCount[j.theme.rawValue, default: 0] += 1
        }
        let topTheme = themeCount.max(by: { $0.value < $1.value })?.key

        let prayers = PrayerWallService.shared.loadRequests().count
        let verses = ScriptureMemoryService.shared.loadVerses().count
        let badges = AchievementService.shared.earnedBadgeIDs.count
        let moments = GodMomentsService.shared.loadMoments().count

        return WrappedStats(
            year: year,
            totalDaysCompleted: totalDays,
            longestStreak: streak,
            journeysCompleted: completed,
            journalCount: yearEntries.count,
            prayerCount: prayers,
            versesMemorized: verses,
            badgesEarned: badges,
            topTheme: topTheme,
            godMomentsCount: moments
        )
    }
}

// MARK: - Slide Enum

enum WrappedSlide {
    case intro(year: Int)
    case bigNumber(value: String, label: String, color: Color, icon: String)
    case topTheme(theme: String)
    case summary(stats: WrappedStats)
    case closing(year: Int)
}

// MARK: - Shareable Card

struct WrappedShareCard: View {
    let stats: WrappedStats

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.20, blue: 0.38),
                        Color(red: 0.08, green: 0.10, blue: 0.22)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                VStack(spacing: geo.size.height * 0.03) {
                    Spacer().frame(height: geo.size.height * 0.08)

                    Image(systemName: "cross.circle.fill")
                        .font(.system(size: geo.size.width * 0.08))
                        .foregroundStyle(.white.opacity(0.6))

                    Text(verbatim: "My \(stats.year) Faith Journey")
                        .font(.system(size: geo.size.width * 0.07, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Spacer().frame(height: geo.size.height * 0.02)

                    // Stats grid
                    VStack(spacing: geo.size.height * 0.02) {
                        HStack(spacing: geo.size.width * 0.06) {
                            shareStatBlock(value: "\(stats.totalDaysCompleted)", label: "Days with God", icon: "calendar", geo: geo)
                            shareStatBlock(value: "\(stats.longestStreak)", label: "Day Streak", icon: "flame.fill", geo: geo)
                        }
                        HStack(spacing: geo.size.width * 0.06) {
                            shareStatBlock(value: "\(stats.journeysCompleted)", label: "Journeys", icon: "flag.checkered", geo: geo)
                            shareStatBlock(value: "\(stats.journalCount)", label: "Reflections", icon: "pencil", geo: geo)
                        }
                        HStack(spacing: geo.size.width * 0.06) {
                            shareStatBlock(value: "\(stats.prayerCount)", label: "Prayers", icon: "hands.sparkles", geo: geo)
                            shareStatBlock(value: "\(stats.badgesEarned)", label: "Badges", icon: "trophy.fill", geo: geo)
                        }
                    }
                    .padding(.horizontal, geo.size.width * 0.08)

                    if let theme = stats.topTheme {
                        VStack(spacing: 4) {
                            Text("Top Journey")
                                .font(.system(size: geo.size.width * 0.03))
                                .foregroundStyle(.white.opacity(0.5))
                            Text(theme)
                                .font(.system(size: geo.size.width * 0.045, weight: .bold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.top, geo.size.height * 0.01)
                    }

                    Spacer()

                    VStack(spacing: geo.size.height * 0.008) {
                        Text("\"He who began a good work in you will carry it on to completion.\"")
                            .font(.system(size: geo.size.width * 0.028).italic())
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                        Text("Philippians 1:6")
                            .font(.system(size: geo.size.width * 0.025, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, geo.size.width * 0.12)

                    HStack(spacing: 6) {
                        Image(systemName: "cross.circle.fill")
                            .font(.system(size: geo.size.width * 0.03))
                        Text("Abide Journey")
                            .font(.system(size: geo.size.width * 0.03, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.3))
                    .padding(.bottom, geo.size.height * 0.06)
                }
            }
        }
    }

    private func shareStatBlock(value: String, label: String, icon: String, geo: GeometryProxy) -> some View {
        VStack(spacing: geo.size.height * 0.008) {
            Image(systemName: icon)
                .font(.system(size: geo.size.width * 0.04))
                .foregroundStyle(.white.opacity(0.5))
            Text(value)
                .font(.system(size: geo.size.width * 0.08, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: geo.size.width * 0.025))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, geo.size.height * 0.015)
        .background(.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    FaithWrappedView()
        .modelContainer(for: [Journey.self, JournalEntry.self], inMemory: true)
}
