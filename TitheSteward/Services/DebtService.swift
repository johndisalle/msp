import Foundation
import SwiftData

@MainActor
class DebtService: ObservableObject {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Debts

    func fetchDebts() -> [DebtItem] {
        let descriptor = FetchDescriptor<DebtItem>(
            sortBy: [SortDescriptor(\.currentBalance)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addDebt(_ debt: DebtItem, to profile: UserProfile) {
        debt.userProfile = profile
        profile.debts.append(debt)
        modelContext.insert(debt)
        try? modelContext.save()
    }

    func deleteDebt(_ debt: DebtItem) {
        modelContext.delete(debt)
        try? modelContext.save()
    }

    // MARK: - Payments

    func addPayment(_ payment: DebtPayment, to debt: DebtItem) {
        payment.debt = debt
        debt.payments.append(payment)
        debt.currentBalance = max(0, debt.currentBalance - payment.amount)
        modelContext.insert(payment)
        try? modelContext.save()
    }

    // MARK: - Snowball Calculator

    func snowballOrder(_ debts: [DebtItem]) -> [DebtItem] {
        debts.filter { $0.currentBalance > 0 }
            .sorted { $0.currentBalance < $1.currentBalance }
    }

    func avalancheOrder(_ debts: [DebtItem]) -> [DebtItem] {
        debts.filter { $0.currentBalance > 0 }
            .sorted { $0.interestRate > $1.interestRate }
    }

    func totalDebt(_ debts: [DebtItem]) -> Decimal {
        debts.reduce(Decimal.zero) { $0 + $1.currentBalance }
    }

    func totalOriginalDebt(_ debts: [DebtItem]) -> Decimal {
        debts.reduce(Decimal.zero) { $0 + $1.originalBalance }
    }

    func overallProgress(_ debts: [DebtItem]) -> Double {
        let original = totalOriginalDebt(debts)
        guard original > 0 else { return 0 }
        let ratio = (original - totalDebt(debts)) / original
        return NSDecimalNumber(decimal: ratio).doubleValue
    }

    func totalMinimumPayments(_ debts: [DebtItem]) -> Decimal {
        debts.reduce(Decimal.zero) { $0 + $1.minimumPayment }
    }
}
