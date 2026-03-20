// UserProfile.swift
// FaithForge
//
// SwiftData model for user profile: XP, streak, level, faith assessment, daily goal.

import Foundation
import SwiftData

// MARK: - Faith Level Tiers

/// Spiritual growth level tiers based on total XP earned.
enum FaithLevel: String, Codable, CaseIterable {
    case novice    = "Novice"
    case seeker    = "Seeker"
    case disciple  = "Disciple"
    case apostle   = "Apostle"
    case shepherd  = "Shepherd"

    /// Minimum XP required to reach this level.
    var xpThreshold: Int {
        switch self {
        case .novice:    return 0
        case .seeker:    return 500
        case .disciple:  return 2_000
        case .apostle:   return 5_000
        case .shepherd:  return 12_000
        }
    }

    /// SF Symbol for level badge.
    var icon: String {
        switch self {
        case .novice:    return "leaf.fill"
        case .seeker:    return "magnifyingglass"
        case .disciple:  return "book.closed.fill"
        case .apostle:   return "star.fill"
        case .shepherd:  return "crown.fill"
        }
    }

    /// Next tier (nil if maxed out).
    var next: FaithLevel? {
        let all = FaithLevel.allCases
        guard let i = all.firstIndex(of: self), i + 1 < all.count else { return nil }
        return all[i + 1]
    }
}

// MARK: - Faith Categories

/// Top-level spiritual discipline categories used across the app.
enum FaithCategory: String, Codable, CaseIterable, Identifiable {
    case theWord    = "The Word"
    case prayer     = "Prayer"
    case mission    = "Mission"
    case restInGod  = "Rest in God"
    case generosity = "Generosity"
    case communion  = "Communion"

    var id: String { rawValue }

    var icon: String {
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

// MARK: - Ring Categories (Home Dashboard)

/// The three Faith Rings shown on the home screen.
enum RingCategory: String, Codable, CaseIterable, Identifiable {
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

    /// Daily XP goal for a full ring.
    var dailyGoal: Int {
        switch self {
        case .word:      return 100
        case .communion: return 80
        case .mission:   return 60
        }
    }
}

// MARK: - Daily Goal Intensity

/// How much daily commitment the user selected during onboarding.
enum DailyGoalIntensity: String, Codable, CaseIterable {
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

    var subtitle: String {
        switch self {
        case .light:    return "~10 min/day"
        case .moderate: return "~20 min/day"
        case .devoted:  return "~30+ min/day"
        }
    }
}

// MARK: - SwiftData Model

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String = ""
    var totalXP: Int = 0
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastCompletionDate: Date?
    /// Stored as FaithCategory raw-value strings.
    var weakAreas: [String] = []
    /// Persisted as raw value of DailyGoalIntensity.
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

    // MARK: Computed helpers

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

    /// 0.0 – 1.0 progress toward the next level.
    var levelProgress: Double {
        let cur = level
        guard let nxt = cur.next else { return 1.0 }
        let range = Double(nxt.xpThreshold - cur.xpThreshold)
        guard range > 0 else { return 1.0 }
        return min(max(Double(totalXP - cur.xpThreshold) / range, 0), 1)
    }

    var xpToNextLevel: Int {
        guard let nxt = level.next else { return 0 }
        return max(nxt.xpThreshold - totalXP, 0)
    }
}
