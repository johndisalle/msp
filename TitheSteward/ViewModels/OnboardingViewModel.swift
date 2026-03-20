import Foundation
import AuthenticationServices

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var displayName: String = ""
    @Published var tithingCommitment: TithingCommitment = .exploring
    @Published var incomeFrequency: IncomeFrequency = .monthly
    @Published var monthlyIncome: String = ""
    @Published var hasDebt: Bool = false
    @Published var primaryChurch: String = ""
    @Published var paydayDays: [Int] = [1, 15]
    @Published var enableReminders: Bool = true

    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case signIn = 1
        case faithQuiz = 2
        case incomeSetup = 3
        case debtOverview = 4
        case churchSetup = 5
        case reminders = 6
        case complete = 7

        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .signIn: return "Sign In"
            case .faithQuiz: return "Your Giving Heart"
            case .incomeSetup: return "Income Setup"
            case .debtOverview: return "Debt Overview"
            case .churchSetup: return "Your Church"
            case .reminders: return "Stay Faithful"
            case .complete: return "You're Ready!"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome: return "Turn your finances into worship"
            case .signIn: return "Secure your journey"
            case .faithQuiz: return "Tell us about your giving journey"
            case .incomeSetup: return "Let's calculate your tithe"
            case .debtOverview: return "Freedom starts with honesty"
            case .churchSetup: return "Where do you worship?"
            case .reminders: return "We'll help you stay on track"
            case .complete: return "Let's steward faithfully together"
            }
        }

        var verse: String {
            switch self {
            case .welcome: return "\"For where your treasure is, there your heart will be also.\" — Matthew 6:21"
            case .signIn: return ""
            case .faithQuiz: return "\"Each of you should give what you have decided in your heart.\" — 2 Corinthians 9:7"
            case .incomeSetup: return "\"Honor the LORD with your wealth, with the firstfruits.\" — Proverbs 3:9"
            case .debtOverview: return "\"The borrower is slave to the lender.\" — Proverbs 22:7"
            case .churchSetup: return "\"Bring the whole tithe into the storehouse.\" — Malachi 3:10"
            case .reminders: return "\"Be faithful in small things.\" — Luke 16:10"
            case .complete: return "\"God loves a cheerful giver.\" — 2 Corinthians 9:7"
            }
        }
    }

    var progress: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var canProceed: Bool {
        switch currentStep {
        case .welcome, .signIn, .complete: return true
        case .faithQuiz: return true // always has a default
        case .incomeSetup: return !monthlyIncome.isEmpty
        case .debtOverview: return true
        case .churchSetup: return true // optional
        case .reminders: return true
        }
    }

    func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
        // Skip debt overview if user has no debt
        if next == .debtOverview && !hasDebt {
            currentStep = .churchSetup
        } else {
            currentStep = next
        }
    }

    func previousStep() {
        guard let prev = OnboardingStep(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = prev
    }

    var suggestedTithe: Double {
        let income = Double(monthlyIncome) ?? 0
        return income * 0.10
    }

    func buildUserProfile() -> UserProfile {
        UserProfile(
            displayName: displayName,
            tithingCommitment: tithingCommitment,
            incomeFrequency: incomeFrequency,
            monthlyIncome: Double(monthlyIncome) ?? 0,
            hasDebt: hasDebt,
            primaryChurch: primaryChurch.isEmpty ? nil : primaryChurch,
            titheReminderEnabled: enableReminders,
            paydayReminderDays: paydayDays
        )
    }

    func saveProfile() {
        let profile = buildUserProfile()
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "user_profile")
            UserDefaults.standard.set(profile.id.uuidString, forKey: "userId")
        }
    }
}
