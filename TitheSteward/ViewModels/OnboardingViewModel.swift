import Foundation
import SwiftData
import AuthenticationServices

@MainActor
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
    @Published var showingRecurringSuggestion = false

    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

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
        case .faithQuiz: return true
        case .incomeSetup: return !monthlyIncome.isEmpty
        case .debtOverview: return true
        case .churchSetup: return true
        case .reminders: return true
        }
    }

    func nextStep() {
        guard let next = OnboardingStep(rawValue: currentStep.rawValue + 1) else { return }
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

    var shouldSuggestRecurring: Bool {
        !monthlyIncome.isEmpty && !primaryChurch.isEmpty
    }

    var suggestedTithe: Decimal {
        let income = Decimal(string: monthlyIncome) ?? 0
        return income * Decimal(string: "0.10")!
    }

    func saveProfile() {
        guard let modelContext = modelContext else { return }

        let profile = UserProfile(
            displayName: displayName,
            tithingCommitment: tithingCommitment,
            incomeFrequency: incomeFrequency,
            monthlyIncome: Decimal(string: monthlyIncome) ?? 0,
            hasDebt: hasDebt,
            primaryChurch: primaryChurch.isEmpty ? nil : primaryChurch,
            titheReminderEnabled: enableReminders,
            paydayReminderDays: paydayDays
        )

        modelContext.insert(profile)

        // Create default budget categories
        for category in BudgetCategory.defaults() {
            category.userProfile = profile
            profile.budgetCategories.append(category)
            modelContext.insert(category)
        }

        try? modelContext.save()
        UserDefaults.standard.set("local", forKey: "appleUserId")
    }

    func setupRecurringTithe() {
        guard let modelContext = modelContext,
              let income = Decimal(string: monthlyIncome),
              income > 0 else { return }

        let titheAmount = income * Decimal(string: "0.10")!

        // Find or create the church recipient
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let recipient = GivingRecipient(name: primaryChurch, type: .church)
        recipient.userProfile = profile
        profile.recipients.append(recipient)
        recipient.isFavorite = true
        modelContext.insert(recipient)

        // Create monthly recurring gift starting next month 1st
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: Date())
        components.month! += 1
        components.day = 1
        let startDate = calendar.date(from: components) ?? Date()

        let gift = RecurringGift(
            amount: titheAmount,
            frequency: .monthly,
            category: .tithe,
            nextDate: startDate
        )
        gift.recipient = recipient
        recipient.recurringGifts.append(gift)
        modelContext.insert(gift)

        try? modelContext.save()

        // Request notification permission
        Task {
            _ = await NotificationService.shared.requestPermission()
        }
    }
}
