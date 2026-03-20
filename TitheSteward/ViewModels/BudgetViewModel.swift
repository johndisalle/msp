import Foundation
import SwiftData

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var showingAddTransaction = false
    @Published var selectedMonth: Date = Date()
    @Published var selectedCategory: BudgetCategory?

    // Add transaction form
    @Published var newAmount: String = ""
    @Published var newDescription: String = ""
    @Published var newNote: String = ""
    @Published var error: AppError?

    private var budgetService: BudgetService?
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.budgetService = BudgetService(modelContext: modelContext)

        // Ensure defaults exist
        if let profile = userProfile {
            budgetService?.ensureDefaultCategories(for: profile)
        }
    }

    var userProfile: UserProfile? {
        guard let modelContext = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first
    }

    var categories: [BudgetCategory] {
        userProfile?.budgetCategories.sorted { $0.sortOrder < $1.sortOrder } ?? []
    }

    var categoryBreakdown: [(category: BudgetCategory, spent: Decimal, budgeted: Decimal)] {
        budgetService?.categoryBreakdown(categories: categories, for: selectedMonth) ?? []
    }

    var totalBudgeted: Decimal {
        budgetService?.totalBudgeted(categories) ?? 0
    }

    var totalSpent: Decimal {
        budgetService?.totalSpentThisMonth(selectedMonth) ?? 0
    }

    var remainingBudget: Decimal {
        totalBudgeted - totalSpent
    }

    var spendingPercentage: Double {
        guard totalBudgeted > 0 else { return 0 }
        let ratio = totalSpent / totalBudgeted
        return min(1.0, NSDecimalNumber(decimal: ratio).doubleValue)
    }

    func addTransaction() {
        guard let amount = Decimal(string: newAmount), amount > 0 else {
            error = .invalidAmount
            return
        }
        guard let category = selectedCategory,
              let service = budgetService else {
            error = .profileNotFound
            return
        }

        let transaction = BudgetTransaction(
            amount: amount,
            descriptionText: newDescription,
            note: newNote.isEmpty ? nil : newNote
        )

        service.addTransaction(transaction, to: category)
        clearForm()
        objectWillChange.send()
    }

    func deleteTransaction(_ transaction: BudgetTransaction) {
        budgetService?.deleteTransaction(transaction)
        objectWillChange.send()
    }

    private func clearForm() {
        newAmount = ""
        newDescription = ""
        newNote = ""
        selectedCategory = nil
        showingAddTransaction = false
    }
}
