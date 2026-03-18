import Foundation
import SwiftData

@Model
final class Journey {
    var id: UUID
    var title: String
    var subtitle: String
    var startDate: Date
    var totalDays: Int
    var currentDay: Int
    var isActive: Bool
    var isCompleted: Bool
    var theme: JourneyTheme
    var focusAreas: [DiscipleshipArea]

    var user: UserProfile?

    @Relationship(deleteRule: .cascade, inverse: \JourneyDay.journey)
    var days: [JourneyDay]

    var progress: Double {
        guard totalDays > 0 else { return 0 }
        return Double(currentDay) / Double(totalDays)
    }

    var daysRemaining: Int {
        max(0, totalDays - currentDay)
    }

    init(
        title: String,
        subtitle: String = "",
        totalDays: Int = 40,
        theme: JourneyTheme = .knowingGod,
        focusAreas: [DiscipleshipArea] = DiscipleshipArea.allCases
    ) {
        self.id = UUID()
        self.title = title
        self.subtitle = subtitle
        self.startDate = Date()
        self.totalDays = totalDays
        self.currentDay = 0
        self.isActive = true
        self.isCompleted = false
        self.theme = theme
        self.focusAreas = focusAreas
        self.days = []
    }
}

enum JourneyTheme: String, Codable, CaseIterable {
    case knowingGod = "Knowing God"
    case obeyingGod = "Obeying God"
    case sharingFaith = "Sharing Faith"
    case bearingFruit = "Bearing Fruit"
    case overcomingDoubt = "Overcoming Doubt"
    case findingPeace = "Finding Peace"
    case spiritualGrowth = "Spiritual Growth"

    var icon: String {
        switch self {
        case .knowingGod: return "book.fill"
        case .obeyingGod: return "checkmark.seal.fill"
        case .sharingFaith: return "megaphone.fill"
        case .bearingFruit: return "leaf.fill"
        case .overcomingDoubt: return "shield.fill"
        case .findingPeace: return "heart.fill"
        case .spiritualGrowth: return "arrow.up.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .knowingGod: return "ThemeBlue"
        case .obeyingGod: return "ThemeGreen"
        case .sharingFaith: return "ThemeOrange"
        case .bearingFruit: return "ThemePurple"
        case .overcomingDoubt: return "ThemeRed"
        case .findingPeace: return "ThemeTeal"
        case .spiritualGrowth: return "ThemeGold"
        }
    }
}

enum DiscipleshipArea: String, Codable, CaseIterable {
    case prayer = "Prayer"
    case scripture = "Scripture"
    case obedience = "Obedience"
    case worship = "Worship"
    case community = "Community"
    case evangelism = "Evangelism"
    case service = "Service"

    var icon: String {
        switch self {
        case .prayer: return "hands.sparkles.fill"
        case .scripture: return "text.book.closed.fill"
        case .obedience: return "checkmark.circle.fill"
        case .worship: return "music.note"
        case .community: return "person.3.fill"
        case .evangelism: return "megaphone.fill"
        case .service: return "hand.raised.fill"
        }
    }
}
