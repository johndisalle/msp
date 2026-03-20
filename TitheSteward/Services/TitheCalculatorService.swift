import Foundation
import SwiftData

@MainActor
class TitheCalculatorService: ObservableObject {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Tithe Calculation

    func calculateTithe(income: Decimal, percentage: Decimal = Decimal(string: "0.10")!) -> Decimal {
        return income * percentage
    }

    func suggestedTithe(for profile: UserProfile) -> Decimal {
        return calculateTithe(income: profile.monthlyIncome)
    }

    func annualTitheGoal(for profile: UserProfile) -> Decimal {
        return calculateTithe(income: profile.monthlyIncome * 12)
    }

    // MARK: - Tracking

    func addRecord(_ record: TitheRecord, to profile: UserProfile) {
        profile.titheRecords.append(record)
        modelContext.insert(record)
        try? modelContext.save()
    }

    func deleteRecord(_ record: TitheRecord) {
        modelContext.delete(record)
        try? modelContext.save()
    }

    func fetchRecords(for month: Date = Date()) -> [TitheRecord] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: month)?.start ?? month
        let endOfMonth = calendar.dateInterval(of: .month, for: month)?.end ?? month

        let descriptor = FetchDescriptor<TitheRecord>(
            predicate: #Predicate { record in
                record.date >= startOfMonth && record.date < endOfMonth
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRecordsForYear(_ date: Date = Date()) -> [TitheRecord] {
        let calendar = Calendar.current
        let startOfYear = calendar.dateInterval(of: .year, for: date)?.start ?? date
        let endOfYear = calendar.dateInterval(of: .year, for: date)?.end ?? date

        let descriptor = FetchDescriptor<TitheRecord>(
            predicate: #Predicate { record in
                record.date >= startOfYear && record.date < endOfYear
            }
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func totalGivenThisMonth(_ date: Date = Date()) -> Decimal {
        fetchRecords(for: date).reduce(Decimal.zero) { $0 + $1.amount }
    }

    func totalGivenThisYear(_ date: Date = Date()) -> Decimal {
        fetchRecordsForYear(date).reduce(Decimal.zero) { $0 + $1.amount }
    }

    func totalByCategory(for month: Date = Date()) -> [GivingCategory: Decimal] {
        var totals: [GivingCategory: Decimal] = [:]
        for record in fetchRecords(for: month) {
            totals[record.category, default: 0] += record.amount
        }
        return totals
    }

    // MARK: - Generosity Score

    func calculateGenerosityScore(for profile: UserProfile) -> GenerosityScore {
        return GenerosityScore(
            totalGivenThisMonth: totalGivenThisMonth(),
            monthlyIncome: profile.monthlyIncome,
            currentStreak: profile.generosityStreak,
            totalGivenThisYear: totalGivenThisYear(),
            annualIncome: profile.monthlyIncome * 12
        )
    }
}
