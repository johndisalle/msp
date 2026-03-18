import Foundation
import WidgetKit

/// Shares journey data between the main app and widget extension via App Groups UserDefaults.
final class WidgetDataService {
    static let shared = WidgetDataService()

    /// App Group identifier — must match the App Group capability in both targets.
    static let appGroupID = "group.com.abidejourney.shared"

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: WidgetDataService.appGroupID)
    }

    // MARK: - Keys

    private enum Keys {
        static let dayNumber = "widget_dayNumber"
        static let totalDays = "widget_totalDays"
        static let verseReference = "widget_verseReference"
        static let verseSnippet = "widget_verseSnippet"
        static let focusArea = "widget_focusArea"
        static let progress = "widget_progress"
        static let journeyTitle = "widget_journeyTitle"
        static let lastUpdated = "widget_lastUpdated"
    }

    // MARK: - Write (called from main app)

    func updateWidgetData(
        dayNumber: Int,
        totalDays: Int,
        verseReference: String,
        verseSnippet: String,
        focusArea: String,
        progress: Double,
        journeyTitle: String
    ) {
        defaults?.set(dayNumber, forKey: Keys.dayNumber)
        defaults?.set(totalDays, forKey: Keys.totalDays)
        defaults?.set(verseReference, forKey: Keys.verseReference)
        defaults?.set(verseSnippet, forKey: Keys.verseSnippet)
        defaults?.set(focusArea, forKey: Keys.focusArea)
        defaults?.set(progress, forKey: Keys.progress)
        defaults?.set(journeyTitle, forKey: Keys.journeyTitle)
        defaults?.set(Date().timeIntervalSince1970, forKey: Keys.lastUpdated)

        // Tell WidgetKit to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Read (called from widget extension)

    struct WidgetData {
        let dayNumber: Int
        let totalDays: Int
        let verseReference: String
        let verseSnippet: String
        let focusArea: String
        let progress: Double
        let journeyTitle: String
        let hasData: Bool
    }

    func readWidgetData() -> WidgetData {
        guard let defaults,
              defaults.object(forKey: Keys.dayNumber) != nil else {
            return WidgetData(
                dayNumber: 0,
                totalDays: 40,
                verseReference: "",
                verseSnippet: "",
                focusArea: "",
                progress: 0,
                journeyTitle: "",
                hasData: false
            )
        }

        return WidgetData(
            dayNumber: defaults.integer(forKey: Keys.dayNumber),
            totalDays: defaults.integer(forKey: Keys.totalDays),
            verseReference: defaults.string(forKey: Keys.verseReference) ?? "",
            verseSnippet: defaults.string(forKey: Keys.verseSnippet) ?? "",
            focusArea: defaults.string(forKey: Keys.focusArea) ?? "",
            progress: defaults.double(forKey: Keys.progress),
            journeyTitle: defaults.string(forKey: Keys.journeyTitle) ?? "",
            hasData: true
        )
    }
}
