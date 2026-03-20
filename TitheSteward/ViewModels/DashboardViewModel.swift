import Foundation

class DashboardViewModel: ObservableObject {
    @Published var userProfile: UserProfile?
    @Published var generosityScore: GenerosityScore?
    @Published var todaysDevotional: Devotional?
    @Published var recentGifts: [TitheRecord] = []

    private let titheService: TitheCalculatorService
    private let devotionalService: DevotionalService

    init(titheService: TitheCalculatorService = TitheCalculatorService(),
         devotionalService: DevotionalService = DevotionalService()) {
        self.titheService = titheService
        self.devotionalService = devotionalService
        loadData()
    }

    func loadData() {
        loadProfile()
        loadDevotional()
        loadRecentGifts()
        calculateScore()
    }

    private func loadProfile() {
        if let data = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            userProfile = profile
        }
    }

    private func loadDevotional() {
        devotionalService.loadTodaysDevotional()
        todaysDevotional = devotionalService.todaysDevotional
    }

    private func loadRecentGifts() {
        recentGifts = Array(titheService.recordsForMonth().sorted { $0.date > $1.date }.prefix(5))
    }

    private func calculateScore() {
        guard let profile = userProfile else { return }
        generosityScore = titheService.calculateGenerosityScore(for: profile)
    }

    // MARK: - Display Helpers

    var titheProgressPercent: Double {
        generosityScore?.progressToTithe ?? 0
    }

    var titheProgressText: String {
        guard let score = generosityScore else { return "$0 of $0" }
        let given = formatCurrency(score.totalGivenThisMonth)
        let goal = formatCurrency(score.monthlyTitheTarget)
        return "\(given) of \(goal)"
    }

    var remainingToTithe: String {
        guard let score = generosityScore else { return "$0" }
        return formatCurrency(score.remainingToTithe)
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

    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
