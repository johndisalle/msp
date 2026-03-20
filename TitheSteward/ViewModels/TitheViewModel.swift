import Foundation

class TitheViewModel: ObservableObject {
    @Published var titheService = TitheCalculatorService()
    @Published var showingAddRecord = false
    @Published var selectedCategory: GivingCategory = .tithe
    @Published var selectedMonth: Date = Date()

    // Add record form fields
    @Published var newAmount: String = ""
    @Published var newRecipient: String = ""
    @Published var newNote: String = ""
    @Published var newIncomeSource: String = "Primary Income"
    @Published var newPaymentMethod: PaymentMethod = .manual

    var userProfile: UserProfile? {
        if let data = UserDefaults.standard.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
            return profile
        }
        return nil
    }

    var monthlyRecords: [TitheRecord] {
        titheService.recordsForMonth(selectedMonth).sorted { $0.date > $1.date }
    }

    var totalGivenThisMonth: Double {
        titheService.totalGivenThisMonth(selectedMonth)
    }

    var suggestedTithe: Double {
        guard let profile = userProfile else { return 0 }
        return titheService.suggestedTithe(for: profile)
    }

    var titheProgress: Double {
        guard suggestedTithe > 0 else { return 0 }
        return min(1.0, totalGivenThisMonth / suggestedTithe)
    }

    var remainingToTithe: Double {
        max(0, suggestedTithe - totalGivenThisMonth)
    }

    var categoryTotals: [(category: GivingCategory, total: Double)] {
        let totals = titheService.totalByCategory(for: selectedMonth)
        return GivingCategory.allCases.compactMap { category in
            guard let total = totals[category], total > 0 else { return nil }
            return (category: category, total: total)
        }
    }

    func addRecord() {
        guard let amount = Double(newAmount), amount > 0 else { return }

        let record = TitheRecord(
            amount: amount,
            incomeSource: newIncomeSource,
            category: selectedCategory,
            recipient: newRecipient,
            note: newNote.isEmpty ? nil : newNote,
            paymentMethod: newPaymentMethod
        )

        titheService.addRecord(record)
        clearForm()
    }

    func deleteRecord(id: UUID) {
        titheService.deleteRecord(id: id)
    }

    private func clearForm() {
        newAmount = ""
        newRecipient = ""
        newNote = ""
        newIncomeSource = "Primary Income"
        selectedCategory = .tithe
        newPaymentMethod = .manual
        showingAddRecord = false
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
