import SwiftUI
import SwiftData
import Charts

struct AdvancedReportsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var trends: [ReportService.MonthlyTrend] = []
    @State private var categories: [ReportService.CategorySummary] = []
    @State private var projection: ReportService.GivingProjection?
    @State private var selectedMonths = 12

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Projection Card
                if let projection = projection, projection.monthsOfData > 0 {
                    ProjectionCard(projection: projection)
                        .padding(.horizontal)
                }

                // Monthly Giving Trend Chart
                if !trends.isEmpty {
                    MonthlyTrendChart(trends: trends)
                        .padding(.horizontal)
                }

                // Category Breakdown
                if !categories.isEmpty {
                    CategoryBreakdownCard(categories: categories)
                        .padding(.horizontal)
                }

                // Tithe Percentage Over Time
                if !trends.isEmpty {
                    TithePercentageChart(trends: trends)
                        .padding(.horizontal)
                }

                // Scripture overlay
                VStack(spacing: 4) {
                    Text("\"Honor the LORD with your wealth, with the firstfruits of all your crops.\"")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    Text("— Proverbs 3:9")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .navigationTitle("Reports")
        .onAppear { loadData() }
    }

    private func loadData() {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let service = ReportService(modelContext: modelContext)
        trends = service.monthlyTrends(for: profile, months: selectedMonths)
        categories = service.categoryBreakdown(for: profile)
        projection = service.projection(for: profile)
    }
}

// MARK: - Projection Card

struct ProjectionCard: View {
    let projection: ReportService.GivingProjection

    var trendIcon: String {
        switch projection.trend {
        case .increasing: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .decreasing: return "arrow.down.right"
        }
    }

    var trendColor: Color {
        switch projection.trend {
        case .increasing: return .green
        case .stable: return .blue
        case .decreasing: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Giving Projection")
                    .font(.headline)
                Spacer()
                Label(projection.trend.rawValue, systemImage: trendIcon)
                    .font(.caption.bold())
                    .foregroundColor(trendColor)
            }

            HStack(spacing: 24) {
                VStack {
                    Text(projection.projectedMonthly.currencyFormatted)
                        .font(.title3.bold())
                    Text("Monthly Avg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 40)

                VStack {
                    Text(projection.projectedAnnual.currencyFormatted)
                        .font(.title3.bold())
                    Text("Annual Projected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 40)

                VStack {
                    Text(String(format: "%.1f%%", projection.projectedTithePercentage))
                        .font(.title3.bold())
                        .foregroundColor(projection.projectedTithePercentage >= 10 ? .green : Color("AccentGold"))
                    Text("of Income")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Based on \(projection.monthsOfData) months of giving data")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

// MARK: - Monthly Trend Chart

struct MonthlyTrendChart: View {
    let trends: [ReportService.MonthlyTrend]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Giving")
                .font(.headline)

            Chart(trends) { trend in
                BarMark(
                    x: .value("Month", trend.monthLabel),
                    y: .value("Amount", trend.totalGiven.doubleValue)
                )
                .foregroundStyle(Color("AccentGold").gradient)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(amount.currencyWhole)
                                .font(.caption2)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label)
                                .font(.caption2)
                                .rotationEffect(.degrees(-45))
                        }
                    }
                }
            }
            .frame(height: 200)

            // Scripture overlay
            Text("\"Whoever sows generously will also reap generously.\" — 2 Corinthians 9:6")
                .font(.caption2.italic())
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

// MARK: - Category Breakdown Card

struct CategoryBreakdownCard: View {
    let categories: [ReportService.CategorySummary]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Giving by Category")
                .font(.headline)

            Chart(categories) { cat in
                SectorMark(
                    angle: .value("Amount", cat.total.doubleValue),
                    innerRadius: .ratio(0.5),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Category", cat.category.rawValue))
                .cornerRadius(4)
            }
            .frame(height: 180)

            ForEach(categories) { cat in
                HStack {
                    Image(systemName: cat.category.icon)
                        .foregroundColor(Color("AccentGold"))
                        .frame(width: 20)
                    Text(cat.category.rawValue)
                        .font(.subheadline)
                    Spacer()
                    Text(cat.total.currencyFormatted)
                        .font(.subheadline.bold())
                    Text("(\(Int(cat.percentage))%)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Tithe Percentage Chart

struct TithePercentageChart: View {
    let trends: [ReportService.MonthlyTrend]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tithe % of Income")
                .font(.headline)

            Chart {
                ForEach(trends) { trend in
                    LineMark(
                        x: .value("Month", trend.monthLabel),
                        y: .value("Percentage", trend.tithePercentOfIncome)
                    )
                    .foregroundStyle(Color("AccentGold"))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Month", trend.monthLabel),
                        y: .value("Percentage", trend.tithePercentOfIncome)
                    )
                    .foregroundStyle(Color("AccentGold"))
                }

                // 10% tithe goal line
                RuleMark(y: .value("Goal", 10))
                    .foregroundStyle(.green.opacity(0.5))
                    .lineStyle(StrokeStyle(dash: [5, 5]))
                    .annotation(position: .trailing, alignment: .leading) {
                        Text("10% Goal")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let pct = value.as(Double.self) {
                            Text("\(Int(pct))%")
                                .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 180)

            Text("\"Bring the whole tithe into the storehouse.\" — Malachi 3:10")
                .font(.caption2.italic())
                .foregroundColor(.secondary)
        }
        .cardStyle()
    }
}

#Preview {
    NavigationStack {
        AdvancedReportsView()
    }
}
