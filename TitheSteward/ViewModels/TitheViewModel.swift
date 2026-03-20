import Foundation
import SwiftData

@MainActor
class TitheViewModel: ObservableObject {
    @Published var showingAddRecord = false
    @Published var selectedCategory: GivingCategory = .tithe
    @Published var selectedMonth: Date = Date()

    // Add record form fields
    @Published var newAmount: String = ""
    @Published var newRecipient: String = ""
    @Published var newNote: String = ""
    @Published var newIncomeSource: String = "Primary Income"
    @Published var newPaymentMethod: PaymentMethod = .manual

    private var titheService: TitheCalculatorService?
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.titheService = TitheCalculatorService(modelContext: modelContext)
    }

    var userProfile: UserProfile? {
        guard let modelContext = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first
    }

    var monthlyRecords: [TitheRecord] {
        titheService?.fetchRecords(for: selectedMonth) ?? []
    }

    var totalGivenThisMonth: Decimal {
        titheService?.totalGivenThisMonth(selectedMonth) ?? 0
    }

    var suggestedTithe: Decimal {
        guard let profile = userProfile else { return 0 }
        return titheService?.suggestedTithe(for: profile) ?? 0
    }

    var titheProgress: Double {
        guard suggestedTithe > 0 else { return 0 }
        let ratio = totalGivenThisMonth / suggestedTithe
        return min(1.0, NSDecimalNumber(decimal: ratio).doubleValue)
    }

    var remainingToTithe: Decimal {
        max(0, suggestedTithe - totalGivenThisMonth)
    }

    var categoryTotals: [(category: GivingCategory, total: Decimal)] {
        guard let service = titheService else { return [] }
        let totals = service.totalByCategory(for: selectedMonth)
        return GivingCategory.allCases.compactMap { category in
            guard let total = totals[category], total > 0 else { return nil }
            return (category: category, total: total)
        }
    }

    func addRecord() {
        guard let amount = Decimal(string: newAmount), amount > 0,
              let profile = userProfile,
              let service = titheService else { return }

        let record = TitheRecord(
            amount: amount,
            incomeSource: newIncomeSource,
            category: selectedCategory,
            recipient: newRecipient,
            note: newNote.isEmpty ? nil : newNote,
            paymentMethod: newPaymentMethod
        )

        service.addRecord(record, to: profile)
        clearForm()
        objectWillChange.send()
    }

    func deleteRecord(_ record: TitheRecord) {
        titheService?.deleteRecord(record)
        objectWillChange.send()
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
}
