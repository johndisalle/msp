// UserProfile.swift
// FaithForgeShared
//
// Shared SwiftData model for user profile. Used by iOS, Watch, and Widget targets.

import Foundation
import SwiftData

// MARK: - Faith Level Tiers

public enum FaithLevel: String, Codable, CaseIterable, Sendable {
    case novice    = "Novice"
    case seeker    = "Seeker"
    case disciple  = "Disciple"
    case apostle   = "Apostle"
    case shepherd  = "Shepherd"

    public var xpThreshold: Int {
        switch self {
        case .novice:    return 0
        case .seeker:    return 500
        case .disciple:  return 2_000
        case .apostle:   return 5_000
        case .shepherd:  return 12_000
        }
    }

    public var icon: String {
        switch self {
        case .novice:    return "leaf.fill"
        case .seeker:    return "magnifyingglass"
        case .disciple:  return "book.closed.fill"
        case .apostle:   return "star.fill"
        case .shepherd:  return "crown.fill"
        }
    }

    public var next: FaithLevel? {
        let all = FaithLevel.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
        return all[i + 1]
    }
}

// MARK: - Faith Categories

public enum FaithCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case theWord    = "The Word"
    case prayer     = "Prayer"
    case mission    = "Mission"
    case restInGod  = "Rest in God"
    case generosity = "Generosity"
    case communion  = "Communion"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .theWord:    return "book.fill"
        case .prayer:     return "hands.sparkles.fill"
        case .mission:    return "figure.walk"
        case .restInGod:  return "moon.stars.fill"
        case .generosity: return "heart.fill"
        case .communion:  return "person.2.fill"
        }
    }
}

// MARK: - Ring Categories

public enum RingCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case word      = "Word"
    case communion = "Communion"
    case mission   = "Mission"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .word:      return "book.fill"
        case .communion: return "hands.sparkles.fill"
        case .mission:   return "figure.walk"
        }
    }

    public var dailyGoal: Int {
        switch self {
        case .word:      return 100
        case .communion: return 80
        case .mission:   return 60
        }
    }
}

// MARK: - Daily Goal Intensity

public enum DailyGoalIntensity: String, Codable, CaseIterable, Sendable {
    case light    = "Light"
    case moderate = "Moderate"
    case devoted  = "Devoted"

    public var questCount: Int {
        switch self {
        case .light:    return 3
        case .moderate: return 5
        case .devoted:  return 7
        }
    }

    public var subtitle: String {
        switch self {
        case .light:    return "~10 min/day"
        case .moderate: return "~20 min/day"
        case .devoted:  return "~30+ min/day"
        }
    }
}

// MARK: - SwiftData Model

@Model
public final class UserProfile {
    public var id: UUID = UUID()
    public var displayName: String = ""
    public var totalXP: Int = 0
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var lastCompletionDate: Date?
    public var weakAreas: [String] = []
    public var dailyGoalRaw: String = DailyGoalIntensity.moderate.rawValue
    public var onboardingCompleted: Bool = false
    public var createdAt: Date = Date()

    public init(
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

    public var dailyGoal: DailyGoalIntensity {
        get { DailyGoalIntensity(rawValue: dailyGoalRaw) ?? .moderate }
        set { dailyGoalRaw = newValue.rawValue }
    }

    public var level: FaithLevel {
        for lvl in FaithLevel.allCases.reversed() {
            if totalXP >= lvl.xpThreshold { return lvl }
        }
        return .novice
    }

    public var levelProgress: Double {
        let cur = level
        guard let nxt = cur.next else { return 1.0 }
        let range = Double(nxt.xpThreshold - cur.xpThreshold)
        guard range > 0 else { return 1.0 }
        return min(max(Double(totalXP - cur.xpThreshold) / range, 0), 1)
    }

    public var xpToNextLevel: Int {
        guard let nxt = level.next else { return 0 }
        return max(nxt.xpThreshold - totalXP, 0)
    }
}
