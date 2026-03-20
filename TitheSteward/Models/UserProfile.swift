import Foundation

struct UserProfile: Codable, Identifiable {
    let id: UUID
    var displayName: String
    var email: String?
    var appleUserId: String?

    // Onboarding responses
    var tithingCommitment: TithingCommitment
    var incomeFrequency: IncomeFrequency
    var monthlyIncome: Double
    var hasDebt: Bool
    var primaryChurch: String?

    // Preferences
    var devotionalReminderTime: Date?
    var titheReminderEnabled: Bool
    var paydayReminderDays: [Int] // Days of month (e.g., [1, 15])

    // Stats
    var joinDate: Date
    var generosityStreak: Int
    var totalGivenAllTime: Double

    init(
        id: UUID = UUID(),
        displayName: String = "",
        email: String? = nil,
        appleUserId: String? = nil,
        tithingCommitment: TithingCommitment = .exploring,
        incomeFrequency: IncomeFrequency = .monthly,
        monthlyIncome: Double = 0,
        hasDebt: Bool = false,
        primaryChurch: String? = nil,
        devotionalReminderTime: Date? = nil,
        titheReminderEnabled: Bool = true,
        paydayReminderDays: [Int] = [1, 15],
        joinDate: Date = Date(),
        generosityStreak: Int = 0,
        totalGivenAllTime: Double = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.appleUserId = appleUserId
        self.tithingCommitment = tithingCommitment
        self.incomeFrequency = incomeFrequency
        self.monthlyIncome = monthlyIncome
        self.hasDebt = hasDebt
        self.primaryChurch = primaryChurch
        self.devotionalReminderTime = devotionalReminderTime
        self.titheReminderEnabled = titheReminderEnabled
        self.paydayReminderDays = paydayReminderDays
        self.joinDate = joinDate
        self.generosityStreak = generosityStreak
        self.totalGivenAllTime = totalGivenAllTime
    }
}

enum TithingCommitment: String, Codable, CaseIterable {
    case exploring = "Exploring"
    case occasional = "Occasional Giver"
    case consistent = "Consistent Tither"
    case generous = "Generous Beyond Tithe"

    var description: String {
        switch self {
        case .exploring: return "I'm learning about tithing and want to start"
        case .occasional: return "I give sometimes but want to be more consistent"
        case .consistent: return "I tithe regularly and want to track faithfully"
        case .generous: return "I tithe and give beyond 10% offerings"
        }
    }

    var encouragementVerse: String {
        switch self {
        case .exploring: return "\"Bring the whole tithe into the storehouse...\" — Malachi 3:10"
        case .occasional: return "\"Each of you should give what you have decided in your heart...\" — 2 Corinthians 9:7"
        case .consistent: return "\"Honor the LORD with your wealth...\" — Proverbs 3:9"
        case .generous: return "\"God loves a cheerful giver.\" — 2 Corinthians 9:7"
        }
    }
}

enum IncomeFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case semimonthly = "Semi-Monthly"
    case monthly = "Monthly"
    case irregular = "Irregular/Freelance"

    var periodsPerYear: Int {
        switch self {
        case .weekly: return 52
        case .biweekly: return 26
        case .semimonthly: return 24
        case .monthly: return 12
        case .irregular: return 12
        }
    }
}
