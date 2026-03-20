import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class ViewModelIntegrationTests: XCTestCase {
    var modelContext: ModelContext!
    var profile: UserProfile!

    override func setUp() async throws {
        let schema = Schema([
            UserProfile.self, TitheRecord.self, BudgetCategory.self,
            BudgetTransaction.self, DebtItem.self, DebtPayment.self,
            DevotionalCompletion.self, GivingRecipient.self, RecurringGift.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        profile = UserProfile(
            displayName: "Test User",
            monthlyIncome: 5000
        )
        modelContext.insert(profile)
        try modelContext.save()
    }

    // MARK: - DashboardViewModel

    func testDashboardViewModelConfigureLoadsProfile() {
        let vm = DashboardViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertNotNil(vm.userProfile)
        XCTAssertEqual(vm.userProfile?.displayName, "Test User")
    }

    func testDashboardViewModelGreeting() {
        let vm = DashboardViewModel()
        vm.configure(modelContext: modelContext)

        let greeting = vm.greeting
        XCTAssertTrue(
            greeting.contains("Test User"),
            "Greeting should contain user's name"
        )
    }

    func testDashboardViewModelGenerosityScoreWithNoGiving() {
        let vm = DashboardViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertEqual(vm.titheProgressPercent, 0)
        XCTAssertEqual(vm.remainingToTithe, "$500")
    }

    func testDashboardViewModelWithTitheRecords() {
        let record = TitheRecord(amount: 250, category: .tithe)
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)
        try? modelContext.save()

        let vm = DashboardViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertEqual(vm.titheProgressPercent, 0.5, accuracy: 0.01)
        XCTAssertFalse(vm.recentGifts.isEmpty)
    }

    func testDashboardViewModelLoadsTodaysDevotional() {
        let vm = DashboardViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertNotNil(vm.todaysDevotional)
        XCTAssertFalse(vm.todaysDevotional?.title.isEmpty ?? true)
    }

    func testDashboardViewModelRefreshReloadsData() {
        let vm = DashboardViewModel()
        vm.configure(modelContext: modelContext)

        // Add a record after initial load
        let record = TitheRecord(amount: 100, category: .offering)
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)
        try? modelContext.save()

        vm.loadData(modelContext: modelContext)

        XCTAssertEqual(vm.recentGifts.count, 1)
    }

    // MARK: - TitheViewModel

    func testTitheViewModelConfigureAndAccess() {
        let vm = TitheViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertNotNil(vm.userProfile)
        XCTAssertEqual(vm.suggestedTithe, 500)
    }

    func testTitheViewModelAddRecord() {
        let vm = TitheViewModel()
        vm.configure(modelContext: modelContext)

        vm.newAmount = "100"
        vm.newRecipient = "My Church"
        vm.selectedCategory = .tithe
        vm.addRecord()

        XCTAssertNil(vm.error)
        XCTAssertEqual(vm.monthlyRecords.count, 1)
        XCTAssertEqual(vm.totalGivenThisMonth, 100)
    }

    func testTitheViewModelAddRecordInvalidAmount() {
        let vm = TitheViewModel()
        vm.configure(modelContext: modelContext)

        vm.newAmount = "abc"
        vm.addRecord()

        XCTAssertEqual(vm.error, .invalidAmount)
        XCTAssertTrue(vm.monthlyRecords.isEmpty)
    }

    func testTitheViewModelDeleteRecord() {
        let vm = TitheViewModel()
        vm.configure(modelContext: modelContext)

        vm.newAmount = "200"
        vm.addRecord()
        XCTAssertEqual(vm.monthlyRecords.count, 1)

        let record = vm.monthlyRecords.first!
        vm.deleteRecord(record)
        XCTAssertEqual(vm.monthlyRecords.count, 0)
    }

    func testTitheViewModelTitheProgress() {
        let vm = TitheViewModel()
        vm.configure(modelContext: modelContext)

        vm.newAmount = "250"
        vm.addRecord()

        XCTAssertEqual(vm.titheProgress, 0.5, accuracy: 0.01)
        XCTAssertEqual(vm.remainingToTithe, 250)
    }

    func testTitheViewModelCategoryTotals() {
        let vm = TitheViewModel()
        vm.configure(modelContext: modelContext)

        vm.newAmount = "100"
        vm.selectedCategory = .tithe
        vm.addRecord()

        vm.newAmount = "50"
        vm.selectedCategory = .offering
        vm.addRecord()

        let totals = vm.categoryTotals
        XCTAssertEqual(totals.count, 2)
    }

    // MARK: - BudgetViewModel

    func testBudgetViewModelConfigureCreatesDefaults() {
        let vm = BudgetViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertFalse(vm.categories.isEmpty, "Should create default budget categories")
    }

    func testBudgetViewModelAddTransaction() {
        let vm = BudgetViewModel()
        vm.configure(modelContext: modelContext)

        let category = vm.categories.first!
        vm.selectedCategory = category
        vm.newAmount = "50"
        vm.newDescription = "Groceries"
        vm.addTransaction()

        XCTAssertNil(vm.error)
        XCTAssertTrue(vm.totalSpent > 0)
    }

    func testBudgetViewModelAddTransactionInvalidAmount() {
        let vm = BudgetViewModel()
        vm.configure(modelContext: modelContext)

        vm.newAmount = ""
        vm.addTransaction()

        XCTAssertEqual(vm.error, .invalidAmount)
    }

    func testBudgetViewModelSpendingPercentage() {
        let vm = BudgetViewModel()
        vm.configure(modelContext: modelContext)

        // totalBudgeted should be > 0 from defaults
        XCTAssertTrue(vm.totalBudgeted > 0)
        XCTAssertEqual(vm.spendingPercentage, 0)
    }

    // MARK: - DevotionalViewModel

    func testDevotionalViewModelLoadsTodaysContent() {
        let vm = DevotionalViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertNotNil(vm.todaysDevotional)
        XCTAssertFalse(vm.todaysDevotional?.title.isEmpty ?? true)
    }

    func testDevotionalViewModelStreakStartsAtZero() {
        let vm = DevotionalViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertEqual(vm.devotionalStreak, 0)
        XCTAssertEqual(vm.streakText, "Start your streak today!")
    }

    func testDevotionalViewModelAllDevotionalsAvailable() {
        let vm = DevotionalViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertEqual(vm.allDevotionals.count, 30)
    }

    // MARK: - GivingViewModel

    func testGivingViewModelConfigureAndAccess() {
        let vm = GivingViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertNotNil(vm.userProfile)
        XCTAssertTrue(vm.recipients.isEmpty)
        XCTAssertTrue(vm.favoriteRecipients.isEmpty)
    }

    func testGivingViewModelAddRecipient() {
        let vm = GivingViewModel()
        vm.configure(modelContext: modelContext)

        vm.newRecipientName = "First Baptist"
        vm.newRecipientType = .church
        vm.addRecipient()

        XCTAssertEqual(vm.recipients.count, 1)
        XCTAssertEqual(vm.recipients.first?.name, "First Baptist")
    }

    func testGivingViewModelToggleFavorite() {
        let vm = GivingViewModel()
        vm.configure(modelContext: modelContext)

        vm.newRecipientName = "My Church"
        vm.addRecipient()

        let recipient = vm.recipients.first!
        XCTAssertFalse(recipient.isFavorite)

        vm.toggleFavorite(recipient)
        XCTAssertTrue(recipient.isFavorite)
        XCTAssertEqual(vm.favoriteRecipients.count, 1)
    }

    func testGivingViewModelDeleteRecipient() {
        let vm = GivingViewModel()
        vm.configure(modelContext: modelContext)

        vm.newRecipientName = "Test Charity"
        vm.newRecipientType = .charity
        vm.addRecipient()
        XCTAssertEqual(vm.recipients.count, 1)

        vm.deleteRecipient(vm.recipients.first!)
        XCTAssertEqual(vm.recipients.count, 0)
    }

    func testGivingViewModelRecurringGiftsInitiallyEmpty() {
        let vm = GivingViewModel()
        vm.configure(modelContext: modelContext)

        XCTAssertTrue(vm.recurringGifts.isEmpty)
        XCTAssertEqual(vm.monthlyRecurringTotal, 0)
    }

    // MARK: - Full Flow: Onboarding → Dashboard

    func testOnboardingCreatesThenDashboardReads() {
        // Simulate onboarding
        let onboardingVM = OnboardingViewModel()
        onboardingVM.configure(modelContext: modelContext)

        // Delete the pre-made profile for this test
        modelContext.delete(profile)
        try? modelContext.save()

        onboardingVM.displayName = "John Smith"
        onboardingVM.monthlyIncome = "6000"
        onboardingVM.tithingCommitment = .consistent
        onboardingVM.primaryChurch = "Grace Chapel"
        onboardingVM.saveProfile()

        // Now dashboard should pick up the new profile
        let dashVM = DashboardViewModel()
        dashVM.configure(modelContext: modelContext)

        XCTAssertEqual(dashVM.userProfile?.displayName, "John Smith")
        XCTAssertTrue(dashVM.greeting.contains("John Smith"))
        XCTAssertEqual(dashVM.generosityScore?.monthlyTitheTarget, 600) // 10% of 6000
    }

    func testAddTitheThenDashboardReflects() {
        // Add a tithe record
        let titheVM = TitheViewModel()
        titheVM.configure(modelContext: modelContext)

        titheVM.newAmount = "500"
        titheVM.selectedCategory = .tithe
        titheVM.newRecipient = "Church"
        titheVM.addRecord()

        // Dashboard should show full tithe met
        let dashVM = DashboardViewModel()
        dashVM.configure(modelContext: modelContext)

        XCTAssertEqual(dashVM.titheProgressPercent, 1.0, accuracy: 0.01)
        XCTAssertEqual(dashVM.recentGifts.count, 1)
    }
}
