import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class TitheCalculatorServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: TitheCalculatorService!
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

        service = TitheCalculatorService(modelContext: modelContext)
    }

    // MARK: - Tithe Calculation

    func testCalculateTitheDefaultPercentage() {
        let tithe = service.calculateTithe(income: 5000)
        XCTAssertEqual(tithe, 500)
    }

    func testCalculateTitheCustomPercentage() {
        let tithe = service.calculateTithe(income: 5000, percentage: Decimal(string: "0.15")!)
        XCTAssertEqual(tithe, 750)
    }

    func testCalculateTitheZeroIncome() {
        let tithe = service.calculateTithe(income: 0)
        XCTAssertEqual(tithe, 0)
    }

    func testSuggestedTitheForProfile() {
        let tithe = service.suggestedTithe(for: profile)
        XCTAssertEqual(tithe, 500)
    }

    func testAnnualTitheGoal() {
        let annual = service.annualTitheGoal(for: profile)
        XCTAssertEqual(annual, 6000) // 5000 * 12 * 0.10
    }

    // MARK: - Record Management

    func testAddRecord() {
        let record = TitheRecord(amount: 250, category: .tithe, recipient: "Church")
        service.addRecord(record, to: profile)

        let records = service.fetchRecords()
        XCTAssertEqual(records.count, 1)
        XCTAssertEqual(records.first?.amount, 250)
    }

    func testDeleteRecord() {
        let record = TitheRecord(amount: 100, category: .offering)
        service.addRecord(record, to: profile)
        XCTAssertEqual(service.fetchRecords().count, 1)

        service.deleteRecord(record)
        XCTAssertEqual(service.fetchRecords().count, 0)
    }

    func testTotalGivenThisMonth() {
        let record1 = TitheRecord(amount: 250, category: .tithe)
        let record2 = TitheRecord(amount: 100, category: .offering)
        let record3 = TitheRecord(amount: 50, category: .missions)
        service.addRecord(record1, to: profile)
        service.addRecord(record2, to: profile)
        service.addRecord(record3, to: profile)

        let total = service.totalGivenThisMonth()
        XCTAssertEqual(total, 400)
    }

    func testTotalGivenThisMonthExcludesOtherMonths() {
        // Current month record
        let current = TitheRecord(amount: 200, category: .tithe)
        service.addRecord(current, to: profile)

        // Past month record (manually set date)
        let past = TitheRecord(
            date: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            amount: 300,
            category: .tithe
        )
        service.addRecord(past, to: profile)

        let total = service.totalGivenThisMonth()
        XCTAssertEqual(total, 200)
    }

    // MARK: - Category Totals

    func testTotalByCategory() {
        service.addRecord(TitheRecord(amount: 500, category: .tithe), to: profile)
        service.addRecord(TitheRecord(amount: 200, category: .tithe), to: profile)
        service.addRecord(TitheRecord(amount: 100, category: .offering), to: profile)
        service.addRecord(TitheRecord(amount: 50, category: .missions), to: profile)

        let totals = service.totalByCategory()
        XCTAssertEqual(totals[.tithe], 700)
        XCTAssertEqual(totals[.offering], 100)
        XCTAssertEqual(totals[.missions], 50)
        XCTAssertNil(totals[.charity])
    }

    // MARK: - Generosity Score

    func testCalculateGenerosityScore() {
        service.addRecord(TitheRecord(amount: 250, category: .tithe), to: profile)

        let score = service.calculateGenerosityScore(for: profile)
        XCTAssertEqual(score.totalGivenThisMonth, 250)
        XCTAssertEqual(score.monthlyIncome, 5000)
        XCTAssertEqual(score.monthlyPercentage, 5.0, accuracy: 0.01)
        XCTAssertEqual(score.remainingToTithe, 250)
        XCTAssertFalse(score.titheGoalMet)
    }

    func testGenerosityScoreTitheGoalMet() {
        service.addRecord(TitheRecord(amount: 500, category: .tithe), to: profile)

        let score = service.calculateGenerosityScore(for: profile)
        XCTAssertTrue(score.titheGoalMet)
        XCTAssertEqual(score.remainingToTithe, 0)
        XCTAssertEqual(score.progressToTithe, 1.0, accuracy: 0.01)
    }

    func testGenerosityScoreOverTithe() {
        service.addRecord(TitheRecord(amount: 750, category: .tithe), to: profile)

        let score = service.calculateGenerosityScore(for: profile)
        XCTAssertTrue(score.titheGoalMet)
        XCTAssertEqual(score.remainingToTithe, 0)
        // progressToTithe caps at 1.0
        XCTAssertEqual(score.progressToTithe, 1.0, accuracy: 0.01)
    }
}
