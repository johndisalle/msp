import Foundation

class BudgetViewModel: ObservableObject {
    @Published var budgetService = BudgetService()
    @Published var showingAddTransaction = false
    @Published var selectedMonth: Date = Date()
    @Published var selectedCategoryId: UUID?

    // Add transaction form
    @Published var newAmount: String = ""
    @Published var newDescription: String = ""
    @Published var newNote: String = ""

    var categories: [BudgetCategory] {
        budgetService.categories.sorted { $0.sortOrder < $1.sortOrder }
    }

    var categoryBreakdown: [(category: BudgetCategory, spent: Double, budgeted: Double)] {
        budgetService.categoryBreakdown(for: selectedMonth)
    }

    var totalBudgeted: Double {
        budgetService.totalBudgeted()
    }

    var totalSpent: Double {
        budgetService.totalSpentThisMonth(selectedMonth)
    }

    var remainingBudget: Double {
        budgetService.remainingBudget(for: selectedMonth)
    }

    var spendingPercentage: Double {
        guard totalBudgeted > 0 else { return 0 }
        return min(1.0, totalSpent / totalBudgeted)
    }

    func transactionsForCategory(_ categoryId: UUID) -> [BudgetTransaction] {
        budgetService.transactionsForMonth(selectedMonth)
            .filter { $0.categoryId == categoryId }
            .sorted { $0.date > $1.date }
    }

    func addTransaction() {
        guard let amount = Double(newAmount), amount > 0,
              let categoryId = selectedCategoryId else { return }

        let transaction = BudgetTransaction(
            amount: amount,
            categoryId: categoryId,
            description: newDescription,
            note: newNote.isEmpty ? nil : newNote
        )

        budgetService.addTransaction(transaction)
        clearForm()
    }

    func deleteTransaction(id: UUID) {
        budgetService.deleteTransaction(id: id)
    }

    func updateCategoryBudget(_ categoryId: UUID, amount: Double) {
        if var category = budgetService.categories.first(where: { $0.id == categoryId }) {
            category.budgetedAmount = amount
            budgetService.updateCategory(category)
        }
    }

    private func clearForm() {
        newAmount = ""
        newDescription = ""
        newNote = ""
        selectedCategoryId = nil
        showingAddTransaction = false
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}
