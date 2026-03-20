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

    // MARK: - Widget Data Refresh After Processing

    func testProcessDueGiftsUpdatesWidgetData() {
        let recipient = GivingRecipient(name: "My Church", type: .church)
        service.addRecipient(recipient, to: profile)

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let gift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: yesterday)
        service.addRecurringGift(gift, to: recipient)

        // Process via the scheduler (which should update widget data)
        RecurringGiftScheduler.shared.processAndSchedule(modelContext: modelContext)

        // Verify widget data was updated with the new tithe record
        let widgetData = WidgetDataService.load()
        XCTAssertGreaterThan(widgetData.amountGivenThisMonth, 0,
            "Widget data should reflect the auto-created tithe record")
        XCTAssertEqual(widgetData.amountGivenThisMonth, 500, accuracy: 0.01,
            "Widget should show $500 given this month")
        XCTAssertGreaterThan(widgetData.titheProgressPercent, 0,
            "Widget should show tithe progress > 0")
    }

    func testProcessNoDueGiftsDoesNotUpdateWidgetData() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        service.addRecipient(recipient, to: profile)

        // Gift with future date — nothing due
        let futureDate = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let gift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, nextDate: futureDate)
        service.addRecurringGift(gift, to: recipient)

        RecurringGiftScheduler.shared.processAndSchedule(modelContext: modelContext)

        let widgetData = WidgetDataService.load()
        XCTAssertEqual(widgetData.amountGivenThisMonth, 0, accuracy: 0.01,
            "Widget should not show any giving when no gifts are due")
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
