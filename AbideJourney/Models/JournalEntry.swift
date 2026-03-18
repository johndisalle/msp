import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var mood: Mood?
    var isVoiceEntry: Bool

    var journeyDay: JourneyDay?

    init(text: String, mood: Mood? = nil, isVoiceEntry: Bool = false) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.updatedAt = Date()
        self.mood = mood
        self.isVoiceEntry = isVoiceEntry
    }
}

enum Mood: String, Codable, CaseIterable {
    case joyful = "😊"
    case peaceful = "😌"
    case grateful = "🙏"
    case reflective = "🤔"
    case struggling = "😔"
    case hopeful = "🌟"

    var label: String {
        switch self {
        case .joyful: return "Joyful"
        case .peaceful: return "Peaceful"
        case .grateful: return "Grateful"
        case .reflective: return "Reflective"
        case .struggling: return "Struggling"
        case .hopeful: return "Hopeful"
        }
    }
}
