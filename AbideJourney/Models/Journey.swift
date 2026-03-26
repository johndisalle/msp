import Foundation
import SwiftData

@Model
final class Journey {
    var id: UUID = UUID()
    var title: String = ""
    var subtitle: String = ""
    var startDate: Date = Date()
    var totalDays: Int = 40
    var currentDay: Int = 0
    var isActive: Bool = true
    var isCompleted: Bool = false
    var theme: JourneyTheme = .knowingGod
    var focusAreas: [DiscipleshipArea] = []
    var isCouple: Bool = false
    var partnerName: String?

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
        self.isCouple = false
        self.partnerName = nil
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
    // Premium deep-dive themes
    case overcomingAnxiety = "Overcoming Anxiety"
    case walkingThroughGrief = "Walking Through Grief"
    case leadingLikeJesus = "Leading Like Jesus"
    case startingOver = "Starting Over"
    case healingRelationships = "Healing Relationships"
    case hearingGodsVoice = "Hearing God's Voice"

    var icon: String {
        switch self {
        case .knowingGod: return "book.fill"
        case .obeyingGod: return "checkmark.seal.fill"
        case .sharingFaith: return "megaphone.fill"
        case .bearingFruit: return "leaf.fill"
        case .overcomingDoubt: return "shield.fill"
        case .findingPeace: return "heart.fill"
        case .spiritualGrowth: return "arrow.up.circle.fill"
        case .overcomingAnxiety: return "heart.circle.fill"
        case .walkingThroughGrief: return "drop.fill"
        case .leadingLikeJesus: return "figure.stand"
        case .startingOver: return "arrow.trianglehead.2.clockwise.rotate.90.circle.fill"
        case .healingRelationships: return "person.2.circle.fill"
        case .hearingGodsVoice: return "flame.fill"
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
        case .overcomingAnxiety: return "ThemeRed"
        case .walkingThroughGrief: return "ThemeBlue"
        case .leadingLikeJesus: return "ThemeOrange"
        case .startingOver: return "ThemeGreen"
        case .healingRelationships: return "ThemePurple"
        case .hearingGodsVoice: return "ThemeGold"
        }
    }

    var isPremium: Bool {
        switch self {
        case .overcomingAnxiety, .walkingThroughGrief, .leadingLikeJesus,
             .startingOver, .healingRelationships, .hearingGodsVoice:
            return true
        default:
            return false
        }
    }

    var subtitle: String {
        switch self {
        case .knowingGod: return "Discover the heart of God through His Word"
        case .obeyingGod: return "Move from knowledge to faithful action"
        case .sharingFaith: return "Grow in confidence to share your story"
        case .bearingFruit: return "Live out the fullness of God's purpose"
        case .overcomingDoubt: return "Build an unshakeable foundation of faith"
        case .findingPeace: return "Rest in God's presence through every storm"
        case .spiritualGrowth: return "Deepen every area of your walk with God"
        case .overcomingAnxiety: return "40 days of peace when your mind won't stop"
        case .walkingThroughGrief: return "Finding God's comfort in seasons of loss"
        case .leadingLikeJesus: return "Servant leadership for everyday life"
        case .startingOver: return "Grace for new beginnings after failure"
        case .healingRelationships: return "Restoring what feels broken"
        case .hearingGodsVoice: return "Learning to listen when God feels silent"
        }
    }

    static var freeThemes: [JourneyTheme] {
        allCases.filter { !$0.isPremium }
    }

    static var premiumThemes: [JourneyTheme] {
        allCases.filter { $0.isPremium }
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
