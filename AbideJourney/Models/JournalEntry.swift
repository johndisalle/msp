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
    case joyful = "joyful"
    case peaceful = "peaceful"
    case grateful = "grateful"
    case reflective = "reflective"
    case struggling = "struggling"
    case hopeful = "hopeful"

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

    var icon: String {
        switch self {
        case .joyful: return "\u{1F60A}"      // smiling face
        case .peaceful: return "\u{1F60C}"     // relieved face
        case .grateful: return "\u{1F64F}"     // folded hands
        case .reflective: return "\u{1F914}"   // thinking face
        case .struggling: return "\u{1F614}"   // pensive face
        case .hopeful: return "\u{1F31F}"      // glowing star
        }
    }
}
