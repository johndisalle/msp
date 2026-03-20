// SharedModels.swift
// FaithForgeWatch
//
// Shared SwiftData models included directly in the Watch target.
// These mirror the models in FaithForgeShared and the main app.
//
// To use the FaithForgeShared package instead:
// 1. In Xcode: File → Add Package Dependencies → Add Local → select FaithForgeShared/
// 2. Add FaithForgeShared to the FaithForgeWatch target
// 3. Re-add "import FaithForgeShared" to Watch Swift files
// 4. Delete this file

import Foundation
import SwiftData

// MARK: - SharedSchema

enum SharedSchema {
    static let allModels: [any PersistentModel.Type] = [
        UserProfile.self,
        DailyQuest.self,
        Badge.self,
        FaithRingProgress.self,
    ]

    static func schema() -> Schema {
        Schema(allModels)
    }
}

// MARK: - Faith Level Tiers

enum FaithLevel: String, Codable, CaseIterable, Sendable {
    case novice    = "Novice"
    case seeker    = "Seeker"
    case disciple  = "Disciple"
    case apostle   = "Apostle"
    case shepherd  = "Shepherd"

    var xpThreshold: Int {
        switch self {
        case .novice:    return 0
        case .seeker:    return 500
        case .disciple:  return 2_000
        case .apostle:   return 5_000
        case .shepherd:  return 12_000
        }
    }

    var icon: String {
        switch self {
        case .novice:    return "leaf.fill"
        case .seeker:    return "magnifyingglass"
        case .disciple:  return "book.closed.fill"
        case .apostle:   return "star.fill"
        case .shepherd:  return "crown.fill"
        }
    }

    var next: FaithLevel? {
        let all = FaithLevel.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
        return all[i + 1]
    }
}

// MARK: - Ring Categories

enum RingCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case word      = "Word"
    case communion = "Communion"
    case mission   = "Mission"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .word:      return "book.fill"
        case .communion: return "hands.sparkles.fill"
        case .mission:   return "figure.walk"
        }
    }

    var dailyGoal: Int {
        switch self {
        case .word:      return 100
        case .communion: return 80
        case .mission:   return 60
        }
    }
}

// MARK: - Daily Goal Intensity

enum DailyGoalIntensity: String, Codable, CaseIterable, Sendable {
    case light    = "Light"
    case moderate = "Moderate"
    case devoted  = "Devoted"

    var questCount: Int {
        switch self {
        case .light:    return 3
        case .moderate: return 5
        case .devoted:  return 7
        }
    }
}

// MARK: - UserProfile

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String = ""
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletionDate: Date?
    var weakAreas: [String] = []
    var dailyGoalRaw: String = DailyGoalIntensity.moderate.rawValue
    var onboardingCompleted: Bool = false
    var createdAt: Date = Date()

    init(
        displayName: String = "",
        dailyGoal: DailyGoalIntensity = .moderate,
        weakAreas: [String] = []
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.dailyGoalRaw = dailyGoal.rawValue
        self.weakAreas = weakAreas
        self.createdAt = Date()
    }

    var dailyGoal: DailyGoalIntensity {
        get { DailyGoalIntensity(rawValue: dailyGoalRaw) ?? .moderate }
        set { dailyGoalRaw = newValue.rawValue }
    }

    var level: FaithLevel {
        for lvl in FaithLevel.allCases.reversed() {
            if totalXP >= lvl.xpThreshold { return lvl }
        }
        return .novice
    }
}

// MARK: - Quest Types

enum QuestType: String, Codable, CaseIterable, Sendable {
    case timer      = "Timer"
    case checkIn    = "Check-in"
    case reflection = "Reflection"
    case quickLog   = "Quick Log"

    var icon: String {
        switch self {
        case .timer:      return "timer"
        case .checkIn:    return "checkmark.circle.fill"
        case .reflection: return "pencil.and.outline"
        case .quickLog:   return "bolt.fill"
        }
    }
}

enum QuestCategory: String, Codable, CaseIterable, Identifiable, Sendable {
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

    var ringCategory: RingCategory? {
        switch self {
        case .theWord:   return .word
        case .prayer:    return .communion
        case .mission:   return .mission
        case .restInGod: return nil
        }
    }
}

// MARK: - DailyQuest

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
    var assignedDate: Date = Date()
    var timerDuration: Int = 0
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

    var category: QuestCategory {
        get { QuestCategory(rawValue: categoryRaw) ?? .theWord }
        set { categoryRaw = newValue.rawValue }
    }

    var type: QuestType {
        get { QuestType(rawValue: typeRaw) ?? .checkIn }
        set { typeRaw = newValue.rawValue }
    }
}

// MARK: - Badge

@Model
final class Badge {
    var id: UUID = UUID()
    var name: String = ""
    var badgeDescription: String = ""
    var icon: String = "star.fill"
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    var categoryTag: String = ""

    init(
        name: String,
        description: String,
        icon: String = "star.fill",
        categoryTag: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.badgeDescription = description
        self.icon = icon
        self.categoryTag = categoryTag
    }
}

// MARK: - FaithRingProgress

@Model
final class FaithRingProgress {
    var id: UUID = UUID()
    var ringCategoryRaw: String = RingCategory.word.rawValue
    var dailyXP: Int = 0
    var date: Date = Date()

    init(ringCategory: RingCategory, date: Date = Date()) {
        self.id = UUID()
        self.ringCategoryRaw = ringCategory.rawValue
        self.dailyXP = 0
        self.date = Calendar.current.startOfDay(for: date)
    }

    var ringCategory: RingCategory {
        get { RingCategory(rawValue: ringCategoryRaw) ?? .word }
        set { ringCategoryRaw = newValue.rawValue }
    }

    var fillFraction: Double {
        let goal = ringCategory.dailyGoal
        guard goal > 0 else { return 0 }
        return min(Double(dailyXP) / Double(goal), 1.0)
    }
}
