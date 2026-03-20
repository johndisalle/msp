import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class DebtServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: DebtService!
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

        profile = UserProfile(displayName: "Test User", monthlyIncome: 5000, hasDebt: true)
        modelContext.insert(profile)
        try modelContext.save()

        service = DebtService(modelContext: modelContext)
    }

    // MARK: - Debt Management

    func testAddDebt() {
        let debt = DebtItem(name: "Chase Visa", originalBalance: 5000, currentBalance: 5000, type: .creditCard)
        service.addDebt(debt, to: profile)

        let debts = service.fetchDebts()
        XCTAssertEqual(debts.count, 1)
        XCTAssertEqual(debts.first?.name, "Chase Visa")
    }

    func testDeleteDebt() {
        let debt = DebtItem(name: "Card", originalBalance: 1000, currentBalance: 1000)
        service.addDebt(debt, to: profile)
        XCTAssertEqual(service.fetchDebts().count, 1)

        service.deleteDebt(debt)
        XCTAssertEqual(service.fetchDebts().count, 0)
    }

    // MARK: - Payments

    func testAddPaymentReducesBalance() {
        let debt = DebtItem(name: "Card", originalBalance: 1000, currentBalance: 1000)
        service.addDebt(debt, to: profile)

        let payment = DebtPayment(amount: 200)
        service.addPayment(payment, to: debt)

        XCTAssertEqual(debt.currentBalance, 800)
        XCTAssertEqual(debt.payments.count, 1)
    }

    func testAddPaymentDoesNotGoBelowZero() {
        let debt = DebtItem(name: "Card", originalBalance: 100, currentBalance: 50)
        service.addDebt(debt, to: profile)

        let payment = DebtPayment(amount: 75)
        service.addPayment(payment, to: debt)

        XCTAssertEqual(debt.currentBalance, 0)
    }

    // MARK: - Snowball Order

    func testSnowballOrderSortsBySmallestBalance() {
        let debt1 = DebtItem(name: "Big", originalBalance: 10000, currentBalance: 8000)
        let debt2 = DebtItem(name: "Small", originalBalance: 500, currentBalance: 300)
        let debt3 = DebtItem(name: "Medium", originalBalance: 3000, currentBalance: 2000)

        let order = service.snowballOrder([debt1, debt2, debt3])
        XCTAssertEqual(order.count, 3)
        XCTAssertEqual(order[0].name, "Small")
        XCTAssertEqual(order[1].name, "Medium")
        XCTAssertEqual(order[2].name, "Big")
    }

    func testSnowballOrderExcludesPaidOffDebts() {
        let debt1 = DebtItem(name: "Active", originalBalance: 1000, currentBalance: 500)
        let debt2 = DebtItem(name: "Paid", originalBalance: 2000, currentBalance: 0)

        let order = service.snowballOrder([debt1, debt2])
        XCTAssertEqual(order.count, 1)
        XCTAssertEqual(order[0].name, "Active")
    }

    // MARK: - Avalanche Order

    func testAvalancheOrderSortsByHighestInterest() {
        let debt1 = DebtItem(name: "Low", originalBalance: 5000, currentBalance: 5000, interestRate: 5.0)
        let debt2 = DebtItem(name: "High", originalBalance: 2000, currentBalance: 2000, interestRate: 24.9)
        let debt3 = DebtItem(name: "Mid", originalBalance: 3000, currentBalance: 3000, interestRate: 12.0)

        let order = service.avalancheOrder([debt1, debt2, debt3])
        XCTAssertEqual(order[0].name, "High")
        XCTAssertEqual(order[1].name, "Mid")
        XCTAssertEqual(order[2].name, "Low")
    }

    // MARK: - Totals and Progress

    func testTotalDebt() {
        let debts = [
            DebtItem(name: "A", originalBalance: 5000, currentBalance: 3000),
            DebtItem(name: "B", originalBalance: 2000, currentBalance: 1000),
        ]

        let total = service.totalDebt(debts)
        XCTAssertEqual(total, 4000)
    }

    func testTotalOriginalDebt() {
        let debts = [
            DebtItem(name: "A", originalBalance: 5000, currentBalance: 3000),
            DebtItem(name: "B", originalBalance: 2000, currentBalance: 1000),
        ]

        let total = service.totalOriginalDebt(debts)
        XCTAssertEqual(total, 7000)
    }

    func testOverallProgress() {
        let debts = [
            DebtItem(name: "A", originalBalance: 10000, currentBalance: 5000),
            DebtItem(name: "B", originalBalance: 10000, currentBalance: 5000),
        ]

        let progress = service.overallProgress(debts)
        XCTAssertEqual(progress, 0.5, accuracy: 0.01)
    }

    func testOverallProgressAllPaid() {
        let debts = [
            DebtItem(name: "A", originalBalance: 5000, currentBalance: 0),
            DebtItem(name: "B", originalBalance: 3000, currentBalance: 0),
        ]

        let progress = service.overallProgress(debts)
        XCTAssertEqual(progress, 1.0, accuracy: 0.01)
    }

    func testOverallProgressNoDebts() {
        let progress = service.overallProgress([])
        XCTAssertEqual(progress, 0)
    }

    func testTotalMinimumPayments() {
        let debts = [
            DebtItem(name: "A", originalBalance: 5000, currentBalance: 5000, minimumPayment: 150),
            DebtItem(name: "B", originalBalance: 2000, currentBalance: 2000, minimumPayment: 50),
        ]

        let total = service.totalMinimumPayments(debts)
        XCTAssertEqual(total, 200)
    }

    // MARK: - DebtItem Model

    func testPercentPaid() {
        let debt = DebtItem(name: "Card", originalBalance: 1000, currentBalance: 250)
        XCTAssertEqual(debt.percentPaid, 0.75, accuracy: 0.01)
    }

    func testPercentPaidFullyPaid() {
        let debt = DebtItem(name: "Card", originalBalance: 1000, currentBalance: 0)
        XCTAssertEqual(debt.percentPaid, 1.0, accuracy: 0.01)
    }

    func testPercentPaidZeroOriginal() {
        let debt = DebtItem(name: "Card", originalBalance: 0, currentBalance: 0)
        XCTAssertEqual(debt.percentPaid, 0)
    }
}
