import Foundation
import SwiftData

@MainActor
class BudgetService: ObservableObject {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Categories

    func fetchCategories() -> [BudgetCategory] {
        let descriptor = FetchDescriptor<BudgetCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func ensureDefaultCategories(for profile: UserProfile) {
        guard profile.budgetCategories.isEmpty else { return }
        for category in BudgetCategory.defaults() {
            category.userProfile = profile
            profile.budgetCategories.append(category)
            modelContext.insert(category)
        }
        try? modelContext.save()
    }

    func addCategory(_ category: BudgetCategory, to profile: UserProfile) {
        category.userProfile = profile
        profile.budgetCategories.append(category)
        modelContext.insert(category)
        try? modelContext.save()
    }

    func deleteCategory(_ category: BudgetCategory) {
        modelContext.delete(category)
        try? modelContext.save()
    }

    // MARK: - Transactions

    func addTransaction(_ transaction: BudgetTransaction, to category: BudgetCategory) {
        transaction.category = category
        category.transactions.append(transaction)
        modelContext.insert(transaction)
        try? modelContext.save()
    }

    func deleteTransaction(_ transaction: BudgetTransaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }

    func transactionsForMonth(_ date: Date = Date(), category: BudgetCategory? = nil) -> [BudgetTransaction] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        let endOfMonth = calendar.dateInterval(of: .month, for: date)?.end ?? date

        let descriptor = FetchDescriptor<BudgetTransaction>(
            predicate: #Predicate { txn in
                txn.date >= startOfMonth && txn.date < endOfMonth
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        var results = (try? modelContext.fetch(descriptor)) ?? []
        if let category = category {
            results = results.filter { $0.category?.persistentModelID == category.persistentModelID }
        }
        return results
    }

    func spentInCategory(_ category: BudgetCategory, for month: Date = Date()) -> Decimal {
        transactionsForMonth(month, category: category).reduce(Decimal.zero) { $0 + $1.amount }
    }

    func totalSpentThisMonth(_ date: Date = Date()) -> Decimal {
        transactionsForMonth(date).reduce(Decimal.zero) { $0 + $1.amount }
    }

    func totalBudgeted(_ categories: [BudgetCategory]) -> Decimal {
        categories.reduce(Decimal.zero) { $0 + $1.budgetedAmount }
    }

    // MARK: - Insights

    func categoryBreakdown(categories: [BudgetCategory], for month: Date = Date()) -> [(category: BudgetCategory, spent: Decimal, budgeted: Decimal)] {
        categories.map { category in
            (category: category, spent: spentInCategory(category, for: month), budgeted: category.budgetedAmount)
        }.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }
}
