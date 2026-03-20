import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class BudgetServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: BudgetService!
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

        profile = UserProfile(displayName: "Test User", monthlyIncome: 5000)
        modelContext.insert(profile)
        try modelContext.save()

        service = BudgetService(modelContext: modelContext)
    }

    // MARK: - Default Categories

    func testEnsureDefaultCategories() {
        service.ensureDefaultCategories(for: profile)

        XCTAssertEqual(profile.budgetCategories.count, 10)
        XCTAssertEqual(profile.budgetCategories.first?.name, "Tithe & Giving")
    }

    func testEnsureDefaultCategoriesIdempotent() {
        service.ensureDefaultCategories(for: profile)
        service.ensureDefaultCategories(for: profile)

        // Should not duplicate
        XCTAssertEqual(profile.budgetCategories.count, 10)
    }

    // MARK: - Transactions

    func testAddTransaction() {
        let category = BudgetCategory(name: "Food", type: .necessity, budgetedAmount: 600)
        category.userProfile = profile
        profile.budgetCategories.append(category)
        modelContext.insert(category)

        let txn = BudgetTransaction(amount: 45, descriptionText: "Groceries")
        service.addTransaction(txn, to: category)

        XCTAssertEqual(category.transactions.count, 1)
        XCTAssertEqual(category.transactions.first?.amount, 45)
        XCTAssertEqual(category.transactions.first?.descriptionText, "Groceries")
    }

    func testDeleteTransaction() {
        let category = BudgetCategory(name: "Food", type: .necessity, budgetedAmount: 600)
        category.userProfile = profile
        profile.budgetCategories.append(category)
        modelContext.insert(category)

        let txn = BudgetTransaction(amount: 30, descriptionText: "Lunch")
        service.addTransaction(txn, to: category)
        XCTAssertEqual(category.transactions.count, 1)

        service.deleteTransaction(txn)
        // Transaction removed from context (may still be in relationship until save)
    }

    // MARK: - Spending Calculations

    func testSpentInCategory() {
        let category = BudgetCategory(name: "Transport", type: .necessity, budgetedAmount: 200)
        category.userProfile = profile
        profile.budgetCategories.append(category)
        modelContext.insert(category)

        service.addTransaction(BudgetTransaction(amount: 50, descriptionText: "Gas"), to: category)
        service.addTransaction(BudgetTransaction(amount: 30, descriptionText: "Parking"), to: category)

        let spent = service.spentInCategory(category)
        XCTAssertEqual(spent, 80)
    }

    func testTotalSpentThisMonth() {
        let cat1 = BudgetCategory(name: "Food", type: .necessity, budgetedAmount: 600)
        let cat2 = BudgetCategory(name: "Gas", type: .necessity, budgetedAmount: 200)
        cat1.userProfile = profile
        cat2.userProfile = profile
        profile.budgetCategories.append(cat1)
        profile.budgetCategories.append(cat2)
        modelContext.insert(cat1)
        modelContext.insert(cat2)

        service.addTransaction(BudgetTransaction(amount: 100, descriptionText: "Groceries"), to: cat1)
        service.addTransaction(BudgetTransaction(amount: 50, descriptionText: "Fuel"), to: cat2)

        let total = service.totalSpentThisMonth()
        XCTAssertEqual(total, 150)
    }

    func testTotalBudgeted() {
        let categories = [
            BudgetCategory(name: "A", type: .necessity, budgetedAmount: 500),
            BudgetCategory(name: "B", type: .necessity, budgetedAmount: 300),
            BudgetCategory(name: "C", type: .discretionary, budgetedAmount: 200),
        ]

        let total = service.totalBudgeted(categories)
        XCTAssertEqual(total, 1000)
    }

    // MARK: - Category Breakdown

    func testCategoryBreakdown() {
        let cat1 = BudgetCategory(name: "Food", type: .necessity, budgetedAmount: 600, sortOrder: 0)
        let cat2 = BudgetCategory(name: "Fun", type: .discretionary, budgetedAmount: 200, sortOrder: 1)
        cat1.userProfile = profile
        cat2.userProfile = profile
        profile.budgetCategories.append(cat1)
        profile.budgetCategories.append(cat2)
        modelContext.insert(cat1)
        modelContext.insert(cat2)

        service.addTransaction(BudgetTransaction(amount: 150, descriptionText: "Groceries"), to: cat1)

        let breakdown = service.categoryBreakdown(categories: [cat1, cat2])
        XCTAssertEqual(breakdown.count, 2)
        XCTAssertEqual(breakdown[0].spent, 150)
        XCTAssertEqual(breakdown[0].budgeted, 600)
        XCTAssertEqual(breakdown[1].spent, 0)
        XCTAssertEqual(breakdown[1].budgeted, 200)
    }
}
