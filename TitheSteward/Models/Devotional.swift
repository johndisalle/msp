import Foundation

struct Devotional: Codable, Identifiable {
    let id: UUID
    var title: String
    var verse: String
    var verseReference: String
    var reflection: String
    var prayerPrompt: String
    var category: DevotionalCategory
    var dayOfCycle: Int

    init(
        id: UUID = UUID(),
        title: String,
        verse: String,
        verseReference: String,
        reflection: String,
        prayerPrompt: String,
        category: DevotionalCategory = .stewardship,
        dayOfCycle: Int = 1
    ) {
        self.id = id
        self.title = title
        self.verse = verse
        self.verseReference = verseReference
        self.reflection = reflection
        self.prayerPrompt = prayerPrompt
        self.category = category
        self.dayOfCycle = dayOfCycle
    }
}

enum DevotionalCategory: String, Codable, CaseIterable {
    case tithing = "Tithing"
    case generosity = "Generosity"
    case stewardship = "Stewardship"
    case debt = "Debt Freedom"
    case contentment = "Contentment"
    case provision = "God's Provision"
    case wisdom = "Financial Wisdom"

    var icon: String {
        switch self {
        case .tithing: return "heart.fill"
        case .generosity: return "gift.fill"
        case .stewardship: return "leaf.fill"
        case .debt: return "lock.open.fill"
        case .contentment: return "sun.max.fill"
        case .provision: return "cloud.sun.fill"
        case .wisdom: return "book.fill"
        }
    }
}

struct DevotionalCompletion: Codable, Identifiable {
    let id: UUID
    var devotionalId: UUID
    var date: Date
    var didPray: Bool
    var personalNote: String?

    init(id: UUID = UUID(), devotionalId: UUID, date: Date = Date(), didPray: Bool = false, personalNote: String? = nil) {
        self.id = id
        self.devotionalId = devotionalId
        self.date = date
        self.didPray = didPray
        self.personalNote = personalNote
    }
}
