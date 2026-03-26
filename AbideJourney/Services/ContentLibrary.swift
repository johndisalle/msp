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
        let prayerText: String
        let reflectionPrompt: String
        let actionSteps: [String]
    }

    /// Returns content for a specific day. Theme-specific banks are used when available,
    /// falling back to the general discipleship area bank.
    func content(for theme: JourneyTheme, area: DiscipleshipArea, dayInArea: Int) -> DayContent {
        let bank = themeContentBank(for: theme) ?? contentBank(for: area)
        let index = (dayInArea - 1) % bank.count
        return bank[index]
    }

    // MARK: - Theme-Specific Content Banks

    /// Returns a dedicated content bank for themes that have their own curated content,
    /// or nil to fall back to the general discipleship area bank.
    private func themeContentBank(for theme: JourneyTheme) -> [DayContent]? {
        switch theme {
        case .overcomingAnxiety:        return Self.anxietyContent
        case .walkingThroughGrief:      return Self.griefContent
        case .leadingLikeJesus:         return Self.leadershipContent
        case .startingOver:             return Self.startingOverContent
        case .healingRelationships:     return Self.healingRelationshipsContent
        case .hearingGodsVoice:         return Self.hearingGodsVoiceContent
        case .findingPeace:             return Self.findingPeaceContent
        case .overcomingDoubt:          return Self.overcomingDoubtContent
        default:                        return nil
        }
    }

    // MARK: - General Content Bank by Area

    /// Returns the full content array for a discipleship area.
    /// Uses the expanded ContentData entries (6-8 per area = 42-56 total).
    private func contentBank(for area: DiscipleshipArea) -> [DayContent] {
        switch area {
        case .prayer:       return Self.prayerContent + Self.prayerContentExpansion
        case .scripture:    return Self.scriptureContent + Self.scriptureContentExpansion
        case .obedience:    return Self.obedienceContent + Self.obedienceContentExpansion
        case .worship:      return Self.worshipContent + Self.worshipContentExpansion
        case .community:    return Self.communityContent + Self.communityContentExpansion
        case .evangelism:   return Self.evangelismContent + Self.evangelismContentExpansion
        case .service:      return Self.serviceContent + Self.serviceContentExpansion
        }
    }
}
