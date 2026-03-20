import Foundation

class BudgetService: ObservableObject {
    @Published var categories: [BudgetCategory] = []
    @Published var transactions: [BudgetTransaction] = []

    private let categoriesKey = "budget_categories"
    private let transactionsKey = "budget_transactions"

    init() {
        loadData()
        if categories.isEmpty {
            categories = BudgetCategory.defaults
            saveCategories()
        }
    }

    // MARK: - Categories

    func addCategory(_ category: BudgetCategory) {
        categories.append(category)
        saveCategories()
    }

    func updateCategory(_ category: BudgetCategory) {
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
            saveCategories()
        }
    }

    func deleteCategory(id: UUID) {
        categories.removeAll { $0.id == id }
        transactions.removeAll { $0.categoryId == id }
        saveCategories()
        saveTransactions()
    }

    // MARK: - Transactions

    func addTransaction(_ transaction: BudgetTransaction) {
        transactions.append(transaction)
        saveTransactions()
    }

    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
        saveTransactions()
    }

    func transactionsForMonth(_ date: Date = Date()) -> [BudgetTransaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }

    func spentInCategory(_ categoryId: UUID, for month: Date = Date()) -> Double {
        transactionsForMonth(month)
            .filter { $0.categoryId == categoryId }
            .reduce(0) { $0 + $1.amount }
    }

    func totalSpentThisMonth(_ date: Date = Date()) -> Double {
        transactionsForMonth(date).reduce(0) { $0 + $1.amount }
    }

    func totalBudgeted() -> Double {
        categories.reduce(0) { $0 + $1.budgetedAmount }
    }

    func remainingBudget(for month: Date = Date()) -> Double {
        totalBudgeted() - totalSpentThisMonth(month)
    }

    // MARK: - Insights

    func categoryBreakdown(for month: Date = Date()) -> [(category: BudgetCategory, spent: Double, budgeted: Double)] {
        categories.map { category in
            (category: category, spent: spentInCategory(category.id, for: month), budgeted: category.budgetedAmount)
        }.sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    func givingPercentage(monthlyIncome: Double, for month: Date = Date()) -> Double {
        guard monthlyIncome > 0 else { return 0 }
        let givingCategories = categories.filter { $0.type == .giving }
        let totalGiving = givingCategories.reduce(0.0) { total, category in
            total + spentInCategory(category.id, for: month)
        }
        return (totalGiving / monthlyIncome) * 100
    }

    // MARK: - Persistence

    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: categoriesKey)
        }
    }

    private func saveTransactions() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: transactionsKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: categoriesKey),
           let cats = try? JSONDecoder().decode([BudgetCategory].self, from: data) {
            categories = cats
        }
        if let data = UserDefaults.standard.data(forKey: transactionsKey),
           let txns = try? JSONDecoder().decode([BudgetTransaction].self, from: data) {
            transactions = txns
        }
    }
}
