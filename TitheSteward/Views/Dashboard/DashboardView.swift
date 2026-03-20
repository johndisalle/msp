import SwiftUI
import SwiftData

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    Text(viewModel.greeting)
                        .font(.title2.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    // Tithe Progress Card
                    TitheProgressCard(
                        progress: viewModel.titheProgressPercent,
                        progressText: viewModel.titheProgressText,
                        remaining: viewModel.remainingToTithe,
                        level: viewModel.levelText
                    )
                    .padding(.horizontal)

                    // Generosity Score
                    GenerosityScoreCard(
                        level: viewModel.levelText,
                        streak: viewModel.streakText,
                        verse: viewModel.levelVerse
                    )
                    .padding(.horizontal)

                    // Today's Devotional
                    if let devotional = viewModel.todaysDevotional {
                        DailyDevotionalCard(devotional: devotional)
                            .padding(.horizontal)
                    }

                    // Recent Giving Activity
                    if !viewModel.recentGifts.isEmpty {
                        RecentGivingCard(gifts: viewModel.recentGifts)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
            .refreshable {
                viewModel.loadData(modelContext: modelContext)
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Loading your stewardship data...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                }
            }
            .errorAlert($viewModel.error)
        }
    }
}

// MARK: - Dashboard Cards

struct TitheProgressCard: View {
    let progress: Double
    let progressText: String
    let remaining: String
    let level: String

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Tithe Progress")
                    .font(.headline)
                Spacer()
                Text("This Month")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color("AccentGold"), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 32, weight: .bold))
                    Text(level)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Text(progressText)
                .font(.subheadline)
                .foregroundColor(.secondary)

            if progress < 1.0 {
                Text("\(remaining) remaining to reach your tithe goal")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Label("Tithe goal met!", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct GenerosityScoreCard: View {
    let level: String
    let streak: String
    let verse: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Generosity Score")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 20) {
                VStack {
                    Image(systemName: "crown.fill")
                        .font(.title2)
                        .foregroundColor(Color("AccentGold"))
                    Text(level)
                        .font(.caption.bold())
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Image(systemName: "flame.fill")
                        .font(.title2)
                        .foregroundColor(.orange)
                    Text(streak)
                        .font(.caption.bold())
                }
            }

            Text(verse)
                .font(.caption.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct DailyDevotionalCard: View {
    let devotional: Devotional

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Color("AccentGold"))
                Text("Today's Stewardship Word")
                    .font(.headline)
                Spacer()
            }

            Text(devotional.title)
                .font(.subheadline.bold())

            Text("\"\(devotional.verse)\"")
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .lineLimit(3)

            Text("— \(devotional.verseReference)")
                .font(.caption)
                .foregroundColor(.secondary)

            NavigationLink(destination: DevotionalDetailView(devotional: devotional)) {
                Text("Read Full Reflection")
                    .font(.caption.bold())
                    .foregroundColor(Color("AccentGold"))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

struct RecentGivingCard: View {
    let gifts: [TitheRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Giving")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    TitheTrackerView()
                }
                .font(.caption)
            }

            ForEach(gifts) { gift in
                HStack {
                    Image(systemName: gift.category.icon)
                        .foregroundColor(Color("AccentGold"))
                        .frame(width: 24)

                    VStack(alignment: .leading) {
                        Text(gift.category.rawValue)
                            .font(.subheadline)
                        Text(gift.recipient.isEmpty ? "Gift" : gift.recipient)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text(gift.amount.currencyFormatted)
                        .font(.subheadline.bold())
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}

#Preview {
    DashboardView()
}
