import Foundation

struct WidgetData: Codable {
    var titheProgressPercent: Double
    var amountGivenThisMonth: Double
    var titheGoal: Double
    var generosityStreak: Int
    var generosityLevel: String
    var todaysVerse: String
    var todaysVerseReference: String
    var debtFreedomPercent: Double

    static var placeholder: WidgetData {
        WidgetData(
            titheProgressPercent: 0.65,
            amountGivenThisMonth: 325,
            titheGoal: 500,
            generosityStreak: 12,
            generosityLevel: "Joyful Tither",
            todaysVerse: "Honor the LORD with your wealth...",
            todaysVerseReference: "Proverbs 3:9",
            debtFreedomPercent: 0.42
        )
    }
}

class WidgetDataService {
    private static let suiteName = "group.com.tithesteward.shared"
    private static let dataKey = "widget_data"

    static func save(_ data: WidgetData) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            defaults.set(encoded, forKey: dataKey)
        }
    }

    static func load() -> WidgetData {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let data = defaults.data(forKey: dataKey),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data) else {
            return .placeholder
        }
        return widgetData
    }

    @MainActor
    static func updateFromServices(
        titheService: TitheCalculatorService,
        devotionalService: DevotionalService,
        profile: UserProfile
    ) {
        let score = titheService.calculateGenerosityScore(for: profile)
        let devotional = devotionalService.todaysDevotional

        let data = WidgetData(
            titheProgressPercent: score.progressToTithe,
            amountGivenThisMonth: NSDecimalNumber(decimal: score.totalGivenThisMonth).doubleValue,
            titheGoal: NSDecimalNumber(decimal: score.monthlyTitheTarget).doubleValue,
            generosityStreak: score.currentStreak,
            generosityLevel: score.level.rawValue,
            todaysVerse: devotional?.verse ?? "",
            todaysVerseReference: devotional?.verseReference ?? "",
            debtFreedomPercent: 0
        )
        save(data)
    }
}
