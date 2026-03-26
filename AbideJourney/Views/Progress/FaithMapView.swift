import SwiftUI
import SwiftData
import Charts

/// Long-term visualization of spiritual growth across all journeys.
/// Shows mood trends, prayer habits, discipleship area progress, and journey history.
struct FaithMapView: View {
    @Query private var journeys: [Journey]
    @Query(sort: \JournalEntry.createdAt) private var journalEntries: [JournalEntry]

    private var allDays: [JourneyDay] {
        journeys.flatMap(\.days).filter(\.isCompleted).sorted { ($0.date ?? .distantPast) < ($1.date ?? .distantPast) }
    }

    private var allCheckIns: [DailyCheckIn] {
        allDays.flatMap(\.checkIns)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerCard

                if !allCheckIns.isEmpty {
                    moodTrendChart
                }

                if allDays.contains(where: { $0.hasPrayed }) {
                    prayerHeatMap
                }

                discipleshipRadar

                journeyTimeline

                lifetimeStats
            }
            .padding(.vertical)
        }
        .ajScreenBackground()
        .navigationTitle("Faith Map")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "map.fill")
                .font(.system(size: 32))
                .foregroundStyle(AJTheme.sage)

            Text("Your Faith Journey")
                .font(AJTheme.subheadlineFont)

            Text("A picture of your spiritual growth over time")
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AJTheme.sage.opacity(0.08))
        )
        .padding(.horizontal)
    }

    // MARK: - Mood Trend

    private var moodTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Over Time")
                .font(AJTheme.subheadlineFont)

            let moodData = weeklyMoodAverages()

            if !moodData.isEmpty {
                Chart(moodData, id: \.week) { point in
                    LineMark(
                        x: .value("Week", point.week),
                        y: .value("Rating", point.average)
                    )
                    .foregroundStyle(AJTheme.sage)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Week", point.week),
                        y: .value("Rating", point.average)
                    )
                    .foregroundStyle(AJTheme.sage.opacity(0.1))
                    .interpolationMethod(.catmullRom)
                }
                .chartYScale(domain: 1...5)
                .chartYAxis {
                    AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                        AxisValueLabel {
                            if let v = value.as(Int.self) {
                                Text(ratingLabel(v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
            }
        }
        .ajCard()
        .padding(.horizontal)
    }

    // MARK: - Prayer Heat Map

    private var prayerHeatMap: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prayer Days by Week")
                .font(AJTheme.subheadlineFont)

            let weeklyPrayer = weeklyPrayerDays()

            if !weeklyPrayer.isEmpty {
                Chart(weeklyPrayer, id: \.week) { point in
                    BarMark(
                        x: .value("Week", point.week),
                        y: .value("Days", point.days)
                    )
                    .foregroundStyle(.blue.gradient)
                    .cornerRadius(4)
                }
                .frame(height: 150)
            }
        }
        .ajCard()
        .padding(.horizontal)
    }

    // MARK: - Discipleship Radar

    private var discipleshipRadar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Discipleship Areas")
                .font(AJTheme.subheadlineFont)

            let areaStats = discipleshipAreaStats()

            ForEach(areaStats, id: \.area) { stat in
                HStack(spacing: 12) {
                    Image(systemName: stat.area.icon)
                        .foregroundStyle(stat.color)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(stat.area.rawValue)
                                .font(AJTheme.bodyFont)
                            Spacer()
                            Text("\(stat.daysCompleted) days")
                                .font(AJTheme.captionFont)
                                .foregroundStyle(AJTheme.secondaryText)
                        }

                        ProgressView(value: stat.progress)
                            .tint(stat.color)
                    }
                }
            }
        }
        .ajCard()
        .padding(.horizontal)
    }

    // MARK: - Journey Timeline

    private var journeyTimeline: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Journey History")
                .font(AJTheme.subheadlineFont)

            let sortedJourneys = journeys.sorted { $0.startDate > $1.startDate }

            ForEach(sortedJourneys) { journey in
                HStack(spacing: 14) {
                    Image(systemName: journey.isCompleted && journey.currentDay >= journey.totalDays ? "checkmark.circle.fill" : "circle.dotted")
                        .foregroundStyle(journey.isCompleted && journey.currentDay >= journey.totalDays ? AJTheme.success : AJTheme.secondaryText)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(journey.title)
                            .font(.subheadline.bold())
                        Text("\(journey.days.filter(\.isCompleted).count)/\(journey.totalDays) days \u{2022} \(journey.startDate, format: .dateTime.month().year())")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                    }

                    Spacer()

                    Text("\(Int(journey.progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(AJTheme.gold)
                }
            }

            if sortedJourneys.isEmpty {
                Text("Start your first journey to see your history here.")
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
            }
        }
        .ajCard()
        .padding(.horizontal)
    }

    // MARK: - Lifetime Stats

    private var lifetimeStats: some View {
        let totalDays = allDays.count
        let totalPrayer = allDays.filter { $0.hasPrayed }.count
        let totalEntries = journalEntries.count
        let totalJourneys = journeys.count

        return VStack(alignment: .leading, spacing: 16) {
            Text("All-Time")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                lifetimeStat(value: "\(totalDays)", label: "Days Completed", icon: "checkmark.circle.fill", color: .green)
                lifetimeStat(value: "\(totalPrayer)", label: "Days Prayed", icon: "hands.sparkles.fill", color: .blue)
                lifetimeStat(value: "\(totalEntries)", label: "Journal Entries", icon: "book.fill", color: .purple)
                lifetimeStat(value: "\(totalJourneys)", label: "Journeys", icon: "map.fill", color: .orange)
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

    private func lifetimeStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Data Helpers

    private struct WeeklyMood {
        let week: String
        let average: Double
    }

    private struct WeeklyPrayer {
        let week: String
        let days: Int
    }

    private struct AreaStat {
        let area: DiscipleshipArea
        let daysCompleted: Int
        let progress: Double
        let color: Color
    }

    private func weeklyMoodAverages() -> [WeeklyMood] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var weeklyData: [(date: Date, label: String, ratings: [Double])] = []

        for checkIn in allCheckIns {
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: checkIn.date)?.start ?? checkIn.date
            if let existing = weeklyData.firstIndex(where: { calendar.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }) {
                weeklyData[existing].ratings.append(ratingToScore(checkIn.rating))
            } else {
                weeklyData.append((date: weekStart, label: formatter.string(from: weekStart), ratings: [ratingToScore(checkIn.rating)]))
            }
        }

        return weeklyData
            .sorted { $0.date < $1.date }
            .suffix(12)
            .map { WeeklyMood(week: $0.label, average: $0.ratings.reduce(0, +) / Double($0.ratings.count)) }
    }

    private func weeklyPrayerDays() -> [WeeklyPrayer] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        var weeklyData: [(date: Date, label: String, days: Int)] = []

        for day in allDays where day.hasPrayed {
            guard let date = day.date else { continue }
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
            if let existing = weeklyData.firstIndex(where: { calendar.isDate($0.date, equalTo: weekStart, toGranularity: .weekOfYear) }) {
                weeklyData[existing].days += 1
            } else {
                weeklyData.append((date: weekStart, label: formatter.string(from: weekStart), days: 1))
            }
        }

        return weeklyData
            .sorted { $0.date < $1.date }
            .suffix(12)
            .map { WeeklyPrayer(week: $0.label, days: $0.days) }
    }

    private func discipleshipAreaStats() -> [AreaStat] {
        let colors: [DiscipleshipArea: Color] = [
            .prayer: .blue, .scripture: .green, .obedience: .orange,
            .worship: .purple, .community: .teal, .evangelism: .red, .service: .yellow
        ]

        let maxDays = max(1, allDays.count)

        return DiscipleshipArea.allCases.map { area in
            let completed = allDays.filter { $0.focusArea == area }.count
            return AreaStat(
                area: area,
                daysCompleted: completed,
                progress: Double(completed) / Double(maxDays),
                color: colors[area] ?? .accent
            )
        }.sorted { $0.daysCompleted > $1.daysCompleted }
    }

    private func ratingToScore(_ rating: CheckInRating) -> Double {
        switch rating {
        case .great: return 5.0
        case .good: return 4.0
        case .okay: return 3.0
        case .tough: return 2.0
        case .missed: return 1.0
        }
    }

    private func ratingLabel(_ value: Int) -> String {
        switch value {
        case 5: return "Great"
        case 4: return "Good"
        case 3: return "Okay"
        case 2: return "Tough"
        case 1: return "Hard"
        default: return ""
        }
    }
}

#Preview {
    NavigationStack {
        FaithMapView()
            .modelContainer(for: [Journey.self, JournalEntry.self], inMemory: true)
    }
}
