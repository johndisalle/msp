import Foundation

class DebtService: ObservableObject {
    @Published var debts: [DebtItem] = []
    @Published var payments: [DebtPayment] = []

    private let debtsKey = "debt_items"
    private let paymentsKey = "debt_payments"

    init() {
        loadData()
    }

    // MARK: - Debts

    func addDebt(_ debt: DebtItem) {
        debts.append(debt)
        saveDebts()
    }

    func updateDebt(_ debt: DebtItem) {
        if let index = debts.firstIndex(where: { $0.id == debt.id }) {
            debts[index] = debt
            saveDebts()
        }
    }

    func deleteDebt(id: UUID) {
        debts.removeAll { $0.id == id }
        payments.removeAll { $0.debtId == id }
        saveDebts()
        savePayments()
    }

    // MARK: - Payments

    func addPayment(_ payment: DebtPayment) {
        payments.append(payment)
        // Update current balance
        if let index = debts.firstIndex(where: { $0.id == payment.debtId }) {
            debts[index].currentBalance = max(0, debts[index].currentBalance - payment.amount)
            saveDebts()
        }
        savePayments()
    }

    func paymentsForDebt(_ debtId: UUID) -> [DebtPayment] {
        payments.filter { $0.debtId == debtId }.sorted { $0.date > $1.date }
    }

    // MARK: - Snowball Calculator

    /// Returns debts ordered by the debt snowball method (smallest balance first)
    func snowballOrder() -> [DebtItem] {
        debts.filter { $0.currentBalance > 0 }
            .sorted { $0.currentBalance < $1.currentBalance }
    }

    /// Returns debts ordered by the avalanche method (highest interest first)
    func avalancheOrder() -> [DebtItem] {
        debts.filter { $0.currentBalance > 0 }
            .sorted { $0.interestRate > $1.interestRate }
    }

    var totalDebt: Double {
        debts.reduce(0) { $0 + $1.currentBalance }
    }

    var totalOriginalDebt: Double {
        debts.reduce(0) { $0 + $1.originalBalance }
    }

    var overallProgress: Double {
        guard totalOriginalDebt > 0 else { return 0 }
        return 1 - (totalDebt / totalOriginalDebt)
    }

    var totalMinimumPayments: Double {
        debts.reduce(0) { $0 + $1.minimumPayment }
    }

    func totalPaidThisMonth(_ date: Date = Date()) -> Double {
        let calendar = Calendar.current
        return payments
            .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Persistence

    private func saveDebts() {
        if let data = try? JSONEncoder().encode(debts) {
            UserDefaults.standard.set(data, forKey: debtsKey)
        }
    }

    private func savePayments() {
        if let data = try? JSONEncoder().encode(payments) {
            UserDefaults.standard.set(data, forKey: paymentsKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: debtsKey),
           let items = try? JSONDecoder().decode([DebtItem].self, from: data) {
            debts = items
        }
        if let data = UserDefaults.standard.data(forKey: paymentsKey),
           let items = try? JSONDecoder().decode([DebtPayment].self, from: data) {
            payments = items
        }
    }
}
