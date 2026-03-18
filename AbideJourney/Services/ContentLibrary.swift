import Foundation

/// Provides devotional content for journey days
final class ContentLibrary {
    static let shared = ContentLibrary()

    private init() {}

    struct DayContent {
        let scriptureReference: String
        let scriptureText: String
        let devotionalTitle: String
        let devotionalText: String
        let reflectionPrompt: String
        let actionSteps: [String]
    }

    /// Returns content for a specific day, cycling through the content bank for the given area.
    /// Each discipleship area has 6-8 unique entries, and the journey cycles through
    /// 5 focus areas weekly, giving 40 unique days across the journey.
    func content(for theme: JourneyTheme, area: DiscipleshipArea, dayInArea: Int) -> DayContent {
        let bank = contentBank(for: area)
        let index = (dayInArea - 1) % bank.count
        return bank[index]
    }

    // MARK: - Content Bank by Area

    /// Returns the full content array for a discipleship area.
    /// Uses the expanded ContentData entries (6-8 per area = 42-56 total).
    private func contentBank(for area: DiscipleshipArea) -> [DayContent] {
        switch area {
        case .prayer:       return Self.prayerContent
        case .scripture:    return Self.scriptureContent
        case .obedience:    return Self.obedienceContent
        case .worship:      return Self.worshipContent
        case .community:    return Self.communityContent
        case .evangelism:   return Self.evangelismContent
        case .service:      return Self.serviceContent
        }
    }
}
