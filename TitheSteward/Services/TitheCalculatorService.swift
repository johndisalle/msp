import Foundation

class TitheCalculatorService: ObservableObject {
    @Published var titheRecords: [TitheRecord] = []

    private let storageKey = "tithe_records"

    init() {
        loadRecords()
    }

    // MARK: - Tithe Calculation

    func calculateTithe(income: Double, percentage: Double = 10.0) -> Double {
        return income * (percentage / 100.0)
    }

    func suggestedTithe(for profile: UserProfile) -> Double {
        return calculateTithe(income: profile.monthlyIncome)
    }

    func annualTitheGoal(for profile: UserProfile) -> Double {
        let periodsPerYear = Double(profile.incomeFrequency.periodsPerYear)
        let incomePerPeriod = profile.monthlyIncome
        // monthlyIncome is already monthly, so multiply by 12
        return calculateTithe(income: incomePerPeriod * 12)
    }

    // MARK: - Tracking

    func addRecord(_ record: TitheRecord) {
        titheRecords.append(record)
        saveRecords()
    }

    func deleteRecord(id: UUID) {
        titheRecords.removeAll { $0.id == id }
        saveRecords()
    }

    func recordsForMonth(_ date: Date = Date()) -> [TitheRecord] {
        let calendar = Calendar.current
        return titheRecords.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .month)
        }
    }

    func recordsForYear(_ date: Date = Date()) -> [TitheRecord] {
        let calendar = Calendar.current
        return titheRecords.filter {
            calendar.isDate($0.date, equalTo: date, toGranularity: .year)
        }
    }

    func totalGivenThisMonth(_ date: Date = Date()) -> Double {
        recordsForMonth(date).reduce(0) { $0 + $1.amount }
    }

    func totalGivenThisYear(_ date: Date = Date()) -> Double {
        recordsForYear(date).reduce(0) { $0 + $1.amount }
    }

    func totalByCategory(for month: Date = Date()) -> [GivingCategory: Double] {
        var totals: [GivingCategory: Double] = [:]
        for record in recordsForMonth(month) {
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

    // MARK: - Persistence

    private func saveRecords() {
        if let data = try? JSONEncoder().encode(titheRecords) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadRecords() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let records = try? JSONDecoder().decode([TitheRecord].self, from: data) {
            titheRecords = records
        }
    }
}
