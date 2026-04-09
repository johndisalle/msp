import SwiftUI
import SwiftData

/// Preview and share your annual "Spotify Wrapped"-style faith report.
struct FaithReportView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var journeys: [Journey]
    @Query private var profiles: [UserProfile]
    @Query(sort: \JournalEntry.createdAt) private var journalEntries: [JournalEntry]

    @State private var showingShareSheet = false
    @State private var pdfURL: URL?
    @State private var isGenerating = false

    private var userName: String { profiles.first?.name ?? "Friend" }

    private var year: Int {
        Calendar.current.component(.year, from: Date())
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AJTheme.sage)

                    Text("Your \(String(year)) Faith Report")
                        .font(AJTheme.headlineFont)

                    Text("A beautiful summary of your spiritual journey this year")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                // Preview stats
                let stats = computeStats()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    previewStat(value: "\(stats.totalDaysCompleted)", label: "Days Completed", icon: "checkmark.circle.fill", color: .green)
                    previewStat(value: "\(stats.totalPrayerMinutes)", label: "Days Prayed", icon: "hands.sparkles.fill", color: .blue)
                    previewStat(value: "\(stats.totalJournalEntries)", label: "Reflections", icon: "book.fill", color: .purple)
                    previewStat(value: "\(stats.longestStreak)", label: "Longest Streak", icon: "flame.fill", color: .orange)
                }
                .padding(.horizontal)

                // Insights
                VStack(alignment: .leading, spacing: 16) {
                    Text("Highlights")
                        .font(AJTheme.subheadlineFont)

                    if !stats.topMood.isEmpty {
                        insightRow(title: "Top Mood", value: stats.topMood, icon: "face.smiling.fill", color: .yellow)
                    }
                    if !stats.topFocusArea.isEmpty {
                        insightRow(title: "Strongest Area", value: stats.topFocusArea, icon: "star.fill", color: .orange)
                    }
                    if !stats.topTheme.isEmpty {
                        insightRow(title: "Favorite Theme", value: stats.topTheme, icon: "heart.fill", color: .red)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(AJTheme.cardBackground)
                        .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                )
                .padding(.horizontal)

                // Generate & Share
                Button {
                    generateAndShare(stats: stats)
                } label: {
                    Group {
                        if isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Generate & Share Report")
                            }
                        }
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AJTheme.sage)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isGenerating)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .ajScreenBackground()
        .navigationTitle("Faith Report")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = pdfURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - Components

    private func previewStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func insightRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                Text(value)
                    .font(.subheadline.bold())
            }
            Spacer()
        }
    }

    // MARK: - Data

    private func computeStats() -> FaithReportService.ReportData {
        let calendar = Calendar.current
        let currentYear = year

        let yearJourneys = journeys.filter { calendar.component(.year, from: $0.startDate) == currentYear }
        let allDays = yearJourneys.flatMap { $0.days ?? [] }.filter(\.isCompleted)
        let yearEntries = journalEntries.filter { calendar.component(.year, from: $0.createdAt) == currentYear }

        // Top mood
        let moodCounts = yearEntries.compactMap(\.mood).reduce(into: [:]) { counts, mood in counts[mood.label, default: 0] += 1 }
        let topMood = moodCounts.max(by: { $0.value < $1.value })?.key ?? ""

        // Top focus area
        let areaCounts = allDays.reduce(into: [:]) { counts, day in counts[day.focusArea.rawValue, default: 0] += 1 }
        let topArea = areaCounts.max(by: { $0.value < $1.value })?.key ?? ""

        // Top theme
        let themeCounts = yearJourneys.reduce(into: [:]) { counts, j in counts[j.theme.rawValue, default: 0] += 1 }
        let topTheme = themeCounts.max(by: { $0.value < $1.value })?.key ?? ""

        // Longest streak
        var longestStreak = 0
        for journey in yearJourneys {
            let info = StreakService.shared.calculateStreak(for: journey)
            longestStreak = max(longestStreak, info.longestStreak)
        }

        // Action steps
        let actionSteps = allDays.flatMap(\.actionSteps).filter(\.isCompleted).count

        // Monthly breakdown
        var monthlyDays = [Int](repeating: 0, count: 12)
        for day in allDays {
            if let date = day.date {
                let month = calendar.component(.month, from: date) - 1
                if month >= 0 && month < 12 { monthlyDays[month] += 1 }
            }
        }

        return FaithReportService.ReportData(
            userName: userName,
            year: currentYear,
            totalDaysCompleted: allDays.count,
            totalPrayerMinutes: allDays.filter { $0.hasPrayed }.count,
            totalJournalEntries: yearEntries.count,
            journeysCompleted: yearJourneys.filter { $0.isCompleted && $0.currentDay >= $0.totalDays }.count,
            longestStreak: longestStreak,
            topMood: topMood,
            topFocusArea: topArea,
            versesRead: allDays.count,
            actionStepsCompleted: actionSteps,
            topTheme: topTheme,
            monthlyDays: monthlyDays
        )
    }

    private func generateAndShare(stats: FaithReportService.ReportData) {
        isGenerating = true
        let data = FaithReportService.shared.generateReport(data: stats)

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AbideJourney-FaithReport-\(year).pdf")
        do {
            try data.write(to: url)
            pdfURL = url
            showingShareSheet = true
        } catch {
            #if DEBUG
            print("[FaithReport] Failed to write PDF: \(error.localizedDescription)")
            #endif
        }
        isGenerating = false
    }
}
