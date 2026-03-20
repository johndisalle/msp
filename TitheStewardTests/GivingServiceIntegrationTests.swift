import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class GivingServiceIntegrationTests: XCTestCase {
    var modelContext: ModelContext!
    var service: GivingService!
    var profile: UserProfile!

    override func setUp() async throws {
        let schema = Schema([
            UserProfile.self, TitheRecord.self, BudgetCategory.self,
            BudgetTransaction.self, DebtItem.self, DebtPayment.self,
            DevotionalCompletion.self, GivingRecipient.self, RecurringGift.self, ChatSession.self,
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

        service = GivingService(modelContext: modelContext)
    }

    // MARK: - Recipient + Recurring Gift Flow

    func testAddRecipientWithRecurringGift() {
        let recipient = GivingRecipient(name: "My Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(
            amount: 500,
            frequency: .monthly,
            category: .tithe,
            nextDate: Date()
        )
        service.addRecurringGift(gift, to: recipient)

        let gifts = service.fetchRecurringGifts()
        XCTAssertEqual(gifts.count, 1)
        XCTAssertEqual(gifts.first?.amount, 500)
        XCTAssertEqual(gifts.first?.recipient?.name, "My Church")
    }

    func testMonthlyRecurringTotalWeekly() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(amount: 100, frequency: .weekly, category: .tithe)
        service.addRecurringGift(gift, to: recipient)

        let total = service.monthlyRecurringTotal()
        // 100 * 4.33 = 433
        XCTAssertEqual(total.doubleValue, 433, accuracy: 1)
    }

    func testMonthlyRecurringTotalBiweekly() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(amount: 200, frequency: .biweekly, category: .tithe)
        service.addRecurringGift(gift, to: recipient)

        let total = service.monthlyRecurringTotal()
        // 200 * 2.17 = 434
        XCTAssertEqual(total.doubleValue, 434, accuracy: 1)
    }

    func testMonthlyRecurringTotalQuarterly() {
        let recipient = GivingRecipient(name: "Charity", type: .charity)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(amount: 300, frequency: .quarterly, category: .charity)
        service.addRecurringGift(gift, to: recipient)

        let total = service.monthlyRecurringTotal()
        // 300 / 3 = 100
        XCTAssertEqual(total, 100)
    }

    func testMonthlyRecurringTotalExcludesInactive() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let activeGift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, isActive: true)
        let inactiveGift = RecurringGift(amount: 200, frequency: .monthly, category: .offering, isActive: false)
        service.addRecurringGift(activeGift, to: recipient)
        service.addRecurringGift(inactiveGift, to: recipient)

        let total = service.monthlyRecurringTotal()
        XCTAssertEqual(total, 500) // Only active gift
    }

    func testDeleteRecurringGift() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(amount: 100, frequency: .monthly, category: .tithe)
        service.addRecurringGift(gift, to: recipient)
        XCTAssertEqual(service.fetchRecurringGifts().count, 1)

        service.deleteRecurringGift(gift)
        XCTAssertEqual(service.fetchRecurringGifts().count, 0)
    }

    func testDeleteRecipientCascadesRecurringGifts() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift1 = RecurringGift(amount: 100, frequency: .monthly, category: .tithe)
        let gift2 = RecurringGift(amount: 50, frequency: .weekly, category: .offering)
        service.addRecurringGift(gift1, to: recipient)
        service.addRecurringGift(gift2, to: recipient)

        XCTAssertEqual(service.fetchRecurringGifts().count, 2)

        service.deleteRecipient(recipient)
        XCTAssertEqual(service.fetchRecurringGifts().count, 0)
    }

    // MARK: - RecurringGift → TitheRecord Auto-Creation

    func testRecurringGiftAutoCreateRecord() {
        let recipient = GivingRecipient(name: "My Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(
            amount: 500,
            frequency: .monthly,
            category: .tithe,
            nextDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        )
        service.addRecurringGift(gift, to: recipient)

        // Process due gifts
        let records = service.processDueRecurringGifts(for: profile)

        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.amount, 500)
        XCTAssertEqual(records.first?.category, .tithe)
        XCTAssertTrue(records.first?.isRecurring ?? false)
        XCTAssertEqual(records.first?.recipient, "My Church")
    }

    func testRecurringGiftSkipsFutureDate() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let futureDate = Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        let gift = RecurringGift(amount: 500, frequency: .monthly, nextDate: futureDate)
        service.addRecurringGift(gift, to: recipient)

        let records = service.processDueRecurringGifts(for: profile)
        XCTAssertTrue(records.isEmpty)
    }

    func testRecurringGiftSkipsInactive() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(
            amount: 500,
            frequency: .monthly,
            nextDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
            isActive: false
        )
        service.addRecurringGift(gift, to: recipient)

        let records = service.processDueRecurringGifts(for: profile)
        XCTAssertTrue(records.isEmpty)
    }

    func testRecurringGiftAdvancesNextDate() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 500, frequency: .monthly, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        _ = service.processDueRecurringGifts(for: profile)

        // Next date should be ~1 month from yesterday
        let expectedNext = Calendar.current.date(byAdding: .month, value: 1, to: yesterday)!
        let diff = Calendar.current.dateComponents([.day], from: gift.nextDate, to: expectedNext)
        XCTAssertEqual(diff.day ?? 99, 0, "Next date should advance by one month")
    }

    // MARK: - Favorites

    // MARK: - Scheduler → Widget Data Pipeline

    func testSchedulerProcessesDueGiftsAndUpdatesCalculator() {
        let recipient = GivingRecipient(name: "My Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        // Process via the scheduler (creates TitheRecords + calls WidgetDataService.updateFromServices)
        RecurringGiftScheduler.shared.processAndSchedule(modelContext: modelContext)

        // Verify through TitheCalculatorService — the same data source WidgetDataService.updateFromServices uses
        let titheService = TitheCalculatorService(modelContext: modelContext)
        let score = titheService.calculateGenerosityScore(for: profile)

        XCTAssertEqual(score.totalGivenThisMonth, 500,
            "Generosity score should reflect the auto-created tithe record")
        XCTAssertGreaterThan(score.progressToTithe, 0,
            "Tithe progress should be > 0 after processing due gift")
        // 500 / 500 (10% of 5000) = 1.0
        XCTAssertEqual(score.progressToTithe, 1.0, accuracy: 0.01,
            "Should show 100% tithe progress for $500 on $5000 income")
    }

    func testSchedulerSkipsFutureGiftsNoRecordsCreated() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let gift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: futureDate)
        service.addRecurringGift(gift, to: recipient)

        RecurringGiftScheduler.shared.processAndSchedule(modelContext: modelContext)

        let titheService = TitheCalculatorService(modelContext: modelContext)
        XCTAssertEqual(titheService.totalGivenThisMonth(), 0,
            "No records should be created when no gifts are due")
    }

    // MARK: - Multiple Due Gifts

    func testProcessMultipleDueGiftsFromSameRecipient() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tithe = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: yesterday)
        let offering = RecurringGift(amount: 100, frequency: .monthly, category: .offering, nextDate: yesterday)
        service.addRecurringGift(tithe, to: recipient)
        service.addRecurringGift(offering, to: recipient)

        let records = service.processDueRecurringGifts(for: profile)

        XCTAssertEqual(records.count, 2)
        let totalCreated = records.reduce(Decimal.zero) { $0 + $1.amount }
        XCTAssertEqual(totalCreated, 600)
    }

    func testProcessMultipleDueGiftsFromDifferentRecipients() {
        let church = GivingRecipient(name: "Church", type: .church)
        let charity = GivingRecipient(name: "Red Cross", type: .charity)
        service.addRecipient(church, to: profile)
        service.addRecipient(charity, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift1 = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: yesterday)
        let gift2 = RecurringGift(amount: 200, frequency: .monthly, category: .charity, nextDate: yesterday)
        service.addRecurringGift(gift1, to: church)
        service.addRecurringGift(gift2, to: charity)

        let records = service.processDueRecurringGifts(for: profile)

        XCTAssertEqual(records.count, 2)
        let recipients = Set(records.map { $0.recipient })
        XCTAssertTrue(recipients.contains("Church"))
        XCTAssertTrue(recipients.contains("Red Cross"))
    }

    func testProcessMixOfDueAndFutureGifts() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        let dueGift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: yesterday)
        let futureGift = RecurringGift(amount: 100, frequency: .weekly, category: .offering, nextDate: nextWeek)
        service.addRecurringGift(dueGift, to: recipient)
        service.addRecurringGift(futureGift, to: recipient)

        let records = service.processDueRecurringGifts(for: profile)

        XCTAssertEqual(records.count, 1, "Only the due gift should be processed")
        XCTAssertEqual(records.first?.amount, 500)
    }

    // MARK: - Annual Frequency

    func testMonthlyRecurringTotalAnnually() {
        let recipient = GivingRecipient(name: "Charity", type: .charity)
        service.addRecipient(recipient, to: profile)

        let gift = RecurringGift(amount: 1200, frequency: .annually, category: .charity)
        service.addRecurringGift(gift, to: recipient)

        let total = service.monthlyRecurringTotal()
        // 1200 / 12 = 100
        XCTAssertEqual(total, 100)
    }

    func testRecurringGiftAdvancesNextDateAnnually() {
        let recipient = GivingRecipient(name: "Charity", type: .charity)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 1200, frequency: .annually, category: .charity, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        _ = service.processDueRecurringGifts(for: profile)

        let expectedNext = Calendar.current.date(byAdding: .year, value: 1, to: yesterday)!
        let diff = Calendar.current.dateComponents([.day], from: gift.nextDate, to: expectedNext)
        XCTAssertEqual(diff.day ?? 99, 0, "Next date should advance by one year")
    }

    func testRecurringGiftAdvancesNextDateWeekly() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 50, frequency: .weekly, category: .offering, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        _ = service.processDueRecurringGifts(for: profile)

        let expectedNext = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: yesterday)!
        let diff = Calendar.current.dateComponents([.day], from: gift.nextDate, to: expectedNext)
        XCTAssertEqual(diff.day ?? 99, 0, "Next date should advance by one week")
    }

    func testRecurringGiftAdvancesNextDateBiweekly() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 100, frequency: .biweekly, category: .tithe, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        _ = service.processDueRecurringGifts(for: profile)

        let expectedNext = Calendar.current.date(byAdding: .weekOfYear, value: 2, to: yesterday)!
        let diff = Calendar.current.dateComponents([.day], from: gift.nextDate, to: expectedNext)
        XCTAssertEqual(diff.day ?? 99, 0, "Next date should advance by two weeks")
    }

    func testRecurringGiftAdvancesNextDateQuarterly() {
        let recipient = GivingRecipient(name: "Charity", type: .charity)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 300, frequency: .quarterly, category: .charity, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        _ = service.processDueRecurringGifts(for: profile)

        let expectedNext = Calendar.current.date(byAdding: .month, value: 3, to: yesterday)!
        let diff = Calendar.current.dateComponents([.day], from: gift.nextDate, to: expectedNext)
        XCTAssertEqual(diff.day ?? 99, 0, "Next date should advance by three months")
    }

    // MARK: - Duplicate Recipient Prevention

    func testMultipleRecipientsWithSameNameAllowed() {
        // The service doesn't prevent duplicates — verify both are stored
        let r1 = GivingRecipient(name: "My Church", type: .church)
        let r2 = GivingRecipient(name: "My Church", type: .church)
        service.addRecipient(r1, to: profile)
        service.addRecipient(r2, to: profile)

        let recipients = service.fetchRecipients()
        let matching = recipients.filter { $0.name == "My Church" }
        XCTAssertEqual(matching.count, 2,
            "Service currently allows duplicate recipient names")
    }

    func testRecurringGiftsIsolatedPerRecipient() {
        let r1 = GivingRecipient(name: "Church A", type: .church)
        let r2 = GivingRecipient(name: "Church B", type: .church)
        service.addRecipient(r1, to: profile)
        service.addRecipient(r2, to: profile)

        let gift1 = RecurringGift(amount: 300, frequency: .monthly, category: .tithe)
        let gift2 = RecurringGift(amount: 200, frequency: .monthly, category: .tithe)
        service.addRecurringGift(gift1, to: r1)
        service.addRecurringGift(gift2, to: r2)

        XCTAssertEqual(r1.recurringGifts.count, 1)
        XCTAssertEqual(r2.recurringGifts.count, 1)
        XCTAssertEqual(r1.recurringGifts.first?.amount, 300)
        XCTAssertEqual(r2.recurringGifts.first?.amount, 200)
    }

    // MARK: - Mixed Frequency Monthly Total

    func testMonthlyRecurringTotalMixedFrequencies() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let weekly = RecurringGift(amount: 100, frequency: .weekly, category: .tithe)      // 433
        let monthly = RecurringGift(amount: 500, frequency: .monthly, category: .tithe)     // 500
        let annually = RecurringGift(amount: 1200, frequency: .annually, category: .charity) // 100
        service.addRecurringGift(weekly, to: recipient)
        service.addRecurringGift(monthly, to: recipient)
        service.addRecurringGift(annually, to: recipient)

        let total = service.monthlyRecurringTotal()
        // 433 + 500 + 100 = 1033
        XCTAssertEqual(total.doubleValue, 1033, accuracy: 1)
    }

    // MARK: - Favorites

    func testFavoriteRecipients() {
        let r1 = GivingRecipient(name: "Church A", type: .church)
        let r2 = GivingRecipient(name: "Charity B", type: .charity)
        service.addRecipient(r1, to: profile)
        service.addRecipient(r2, to: profile)

        r1.isFavorite = true
        service.save()

        let favorites = service.favoriteRecipients()
        XCTAssertEqual(favorites.count, 1)
        XCTAssertEqual(favorites.first?.name, "Church A")
    }
}
