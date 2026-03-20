import Foundation
import SwiftData

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var generosityScore: GenerosityScore?
    @Published var todaysDevotional: Devotional?
    @Published var recentGifts: [TitheRecord] = []

    private var titheService: TitheCalculatorService?
    private var devotionalService: DevotionalService?

    func configure(modelContext: ModelContext) {
        self.titheService = TitheCalculatorService(modelContext: modelContext)
        self.devotionalService = DevotionalService(modelContext: modelContext)
        loadData(modelContext: modelContext)
    }

    func loadData(modelContext: ModelContext) {
        loadProfile(modelContext: modelContext)
        loadDevotional()
        loadRecentGifts()
        calculateScore()
    }

    private func loadProfile(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<UserProfile>()
        userProfile = (try? modelContext.fetch(descriptor))?.first
    }

    private func loadDevotional() {
        devotionalService?.loadTodaysDevotional()
        todaysDevotional = devotionalService?.todaysDevotional
    }

    private func loadRecentGifts() {
        guard let service = titheService else { return }
        recentGifts = Array(service.fetchRecords().prefix(5))
    }

    private func calculateScore() {
        guard let profile = userProfile, let service = titheService else { return }
        generosityScore = service.calculateGenerosityScore(for: profile)
    }

    // MARK: - Display Helpers

    var titheProgressPercent: Double {
        generosityScore?.progressToTithe ?? 0
    }

    var titheProgressText: String {
        guard let score = generosityScore else { return "$0 of $0" }
        return "\(score.totalGivenThisMonth.currencyWhole) of \(score.monthlyTitheTarget.currencyWhole)"
    }

    var remainingToTithe: String {
        guard let score = generosityScore else { return "$0" }
        return score.remainingToTithe.currencyWhole
    }

    var streakText: String {
        guard let score = generosityScore else { return "0 months" }
        let months = score.currentStreak
        return "\(months) month\(months == 1 ? "" : "s")"
    }

    var levelText: String {
        generosityScore?.level.rawValue ?? "Seed Planter"
    }

    var levelVerse: String {
        generosityScore?.level.verse ?? ""
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userProfile?.displayName ?? "Friend"
        switch hour {
        case 5..<12: return "Good morning, \(name)"
        case 12..<17: return "Good afternoon, \(name)"
        default: return "Good evening, \(name)"
        }
    }
}
