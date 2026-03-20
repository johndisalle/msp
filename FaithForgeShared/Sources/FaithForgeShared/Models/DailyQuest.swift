// DailyQuest.swift
// FaithForgeShared
//
// Shared SwiftData model for quests.

import Foundation
import SwiftData

public enum QuestType: String, Codable, CaseIterable, Sendable {
    case timer      = "Timer"
    case checkIn    = "Check-in"
    case reflection = "Reflection"
    case quickLog   = "Quick Log"

    public var icon: String {
        switch self {
        case .timer:      return "timer"
        case .checkIn:    return "checkmark.circle.fill"
        case .reflection: return "pencil.and.outline"
        case .quickLog:   return "bolt.fill"
        }
    }
}

public enum QuestCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case theWord   = "The Word"
    case prayer    = "Prayer"
    case mission   = "Mission"
    case restInGod = "Rest in God"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .theWord:   return "book.fill"
        case .prayer:    return "hands.sparkles.fill"
        case .mission:   return "figure.walk"
        case .restInGod: return "moon.stars.fill"
        }
    }

    public var ringCategory: RingCategory? {
        switch self {
        case .theWord:   return .word
        case .prayer:    return .communion
        case .mission:   return .mission
        case .restInGod: return nil
        }
    }
}

@Model
public final class DailyQuest {
    public var id: UUID = UUID()
    public var title: String = ""
    public var questDescription: String = ""
    public var categoryRaw: String = QuestCategory.theWord.rawValue
    public var typeRaw: String = QuestType.checkIn.rawValue
    public var xpReward: Int = 25
    public var isCompleted: Bool = false
    public var completedDate: Date?
    public var assignedDate: Date = Date()
    public var timerDuration: Int = 0
    public var reflectionText: String = ""
    public var sortOrder: Int = 0

    public init(
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

    public var category: QuestCategory {
        get { QuestCategory(rawValue: categoryRaw) ?? .theWord }
        set { categoryRaw = newValue.rawValue }
    }

    public var type: QuestType {
        get { QuestType(rawValue: typeRaw) ?? .checkIn }
        set { typeRaw = newValue.rawValue }
    }
}
