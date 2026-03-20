// CommunityChallenge.swift
// FaithForge
//
// Data model for time-limited community challenges with shared goals.

import Foundation
import SwiftData

/// Challenge difficulty / scope.
enum ChallengeType: String, Codable, CaseIterable {
    case daily  = "Daily Sprint"
    case weekly = "Weekly Quest"
    case epic   = "Epic Challenge"

    var icon: String {
        switch self {
        case .daily:  return "bolt.fill"
        case .weekly: return "calendar.badge.clock"
        case .epic:   return "trophy.fill"
        }
    }

    var durationDays: Int {
        switch self {
        case .daily:  return 1
        case .weekly: return 7
        case .epic:   return 30
        }
    }
}

@Model
final class CommunityChallenge {
    var id: UUID = UUID()
    var title: String = ""
    var challengeDescription: String = ""
    var typeRaw: String = ChallengeType.weekly.rawValue
    var categoryRaw: String = QuestCategory.theWord.rawValue
    /// Total XP goal for the community to hit collectively.
    var communityXPGoal: Int = 10_000
    /// Current community-wide XP progress.
    var communityXPCurrent: Int = 0
    /// The user's personal XP contribution to this challenge.
    var myContribution: Int = 0
    var participantCount: Int = 0
    var isJoined: Bool = false
    var startDate: Date = Date()
    var endDate: Date = Date()
    /// XP bonus awarded on community goal completion.
    var bonusXP: Int = 50
    var isCompleted: Bool = false

    init(
        title: String,
        description: String,
        type: ChallengeType,
        category: QuestCategory,
        communityXPGoal: Int,
        bonusXP: Int = 50,
        startDate: Date = Date(),
        endDate: Date? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.challengeDescription = description
        self.typeRaw = type.rawValue
        self.categoryRaw = category.rawValue
        self.communityXPGoal = communityXPGoal
        self.bonusXP = bonusXP
        self.startDate = startDate
        self.endDate = endDate ?? Calendar.current.date(
            byAdding: .day,
            value: type.durationDays,
            to: startDate
        )!
    }

    var type: ChallengeType {
        get { ChallengeType(rawValue: typeRaw) ?? .weekly }
        set { typeRaw = newValue.rawValue }
    }

    var category: QuestCategory {
        get { QuestCategory(rawValue: categoryRaw) ?? .theWord }
        set { categoryRaw = newValue.rawValue }
    }

    /// 0.0 – 1.0 community progress.
    var communityProgress: Double {
        guard communityXPGoal > 0 else { return 0 }
        return min(Double(communityXPCurrent) / Double(communityXPGoal), 1.0)
    }

    /// Whether the challenge is still active.
    var isActive: Bool {
        let now = Date()
        return now >= startDate && now <= endDate && !isCompleted
    }

    /// Days remaining.
    var daysRemaining: Int {
        max(Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0, 0)
    }

    // MARK: - Seed Challenges

    static var seedChallenges: [CommunityChallenge] {
        let now = Date()
        return [
            CommunityChallenge(
                title: "Scripture Sprint",
                description: "As a community, let's read 10,000 XP worth of Scripture this week!",
                type: .weekly,
                category: .theWord,
                communityXPGoal: 10_000,
                bonusXP: 75,
                startDate: now
            ),
            CommunityChallenge(
                title: "Prayer Chain",
                description: "Join hundreds in a week-long prayer challenge. Every minute counts!",
                type: .weekly,
                category: .prayer,
                communityXPGoal: 8_000,
                bonusXP: 60,
                startDate: now
            ),
            CommunityChallenge(
                title: "30 Days of Service",
                description: "Commit to daily acts of service for an entire month. Epic rewards await!",
                type: .epic,
                category: .mission,
                communityXPGoal: 50_000,
                bonusXP: 200,
                startDate: now
            ),
            CommunityChallenge(
                title: "Daily Devotion Dash",
                description: "Complete your Word quests today. Small steps, big faith!",
                type: .daily,
                category: .theWord,
                communityXPGoal: 2_000,
                bonusXP: 25,
                startDate: now
            ),
        ]
    }
}
