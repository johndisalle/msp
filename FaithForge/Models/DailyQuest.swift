// DailyQuest.swift
// FaithForge
//
// SwiftData model for individual quests: type, category, XP, completion state.

import Foundation
import SwiftData

// MARK: - Quest Type

/// The interaction mode for completing a quest.
enum QuestType: String, Codable, CaseIterable {
    case timer      = "Timer"        // Timed activity (prayer, meditation)
    case checkIn    = "Check-in"     // Simple tap-to-complete
    case reflection = "Reflection"   // Free-text journal entry
    case quickLog   = "Quick Log"    // One-tap log (e.g., "I gave today")

    var icon: String {
        switch self {
        case .timer:      return "timer"
        case .checkIn:    return "checkmark.circle.fill"
        case .reflection: return "pencil.and.outline"
        case .quickLog:   return "bolt.fill"
        }
    }
}

// MARK: - Quest Category (maps to ring + faith area)

/// Which ring / faith area a quest contributes to.
enum QuestCategory: String, Codable, CaseIterable, Identifiable {
    case theWord   = "The Word"
    case prayer    = "Prayer"
    case mission   = "Mission"
    case restInGod = "Rest in God"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .theWord:   return "book.fill"
        case .prayer:    return "hands.sparkles.fill"
        case .mission:   return "figure.walk"
        case .restInGod: return "moon.stars.fill"
        }
    }

    /// Which Faith Ring this category contributes XP toward.
    var ringCategory: RingCategory? {
        switch self {
        case .theWord:   return .word
        case .prayer:    return .communion
        case .mission:   return .mission
        case .restInGod: return nil // tracked via HealthKit, not a ring
        }
    }
}

// MARK: - SwiftData Model

@Model
final class DailyQuest {
    var id: UUID = UUID()
    var title: String = ""
    var questDescription: String = ""
    var categoryRaw: String = QuestCategory.theWord.rawValue
    var typeRaw: String = QuestType.checkIn.rawValue
    var xpReward: Int = 25
    var isCompleted: Bool = false
    var completedDate: Date?
    /// Date this quest was assigned for (start of day).
    var assignedDate: Date = Date()
    /// Timer duration in seconds (only for .timer quests).
    var timerDuration: Int = 0
    /// Reflection text entered by user.
    var reflectionText: String = ""
    var sortOrder: Int = 0

    init(
        title: String,
        description: String = "",
        category: QuestCategory,
        type: QuestType,
        xpReward: Int = 25,
        timerDuration: Int = 0,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.questDescription = description
        self.categoryRaw = category.rawValue
        self.typeRaw = type.rawValue
        self.xpReward = xpReward
        self.timerDuration = timerDuration
        self.sortOrder = sortOrder
        self.assignedDate = Calendar.current.startOfDay(for: Date())
    }

    // MARK: Computed helpers

    var category: QuestCategory {
        get { QuestCategory(rawValue: categoryRaw) ?? .theWord }
        set { categoryRaw = newValue.rawValue }
    }

    var type: QuestType {
        get { QuestType(rawValue: typeRaw) ?? .checkIn }
        set { typeRaw = newValue.rawValue }
    }
}
