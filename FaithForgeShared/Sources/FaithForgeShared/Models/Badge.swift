// Badge.swift
// FaithForgeShared

import Foundation
import SwiftData

@Model
public final class Badge {
    public var id: UUID = UUID()
    public var name: String = ""
    public var badgeDescription: String = ""
    public var icon: String = "star.fill"
    public var isUnlocked: Bool = false
    public var unlockedDate: Date?
    public var categoryTag: String = ""

    public init(
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

    public func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedDate = Date()
    }

    public static var seedBadges: [Badge] {
        [
            Badge(name: "First Step",       description: "Complete your first quest",              icon: "shoeprints.fill",        categoryTag: "milestone"),
            Badge(name: "Week Warrior",     description: "Maintain a 7-day streak",                icon: "flame.fill",             categoryTag: "streak"),
            Badge(name: "Word Scholar",     description: "Complete 10 Word quests",                icon: "book.closed.fill",       categoryTag: "theWord"),
            Badge(name: "Prayer Warrior",   description: "Log 30 minutes of prayer",              icon: "hands.sparkles.fill",    categoryTag: "prayer"),
            Badge(name: "Generous Heart",   description: "Complete 5 generosity quests",           icon: "heart.fill",             categoryTag: "mission"),
            Badge(name: "Sabbath Keeper",   description: "Log 3 Rest in God quests",               icon: "moon.stars.fill",        categoryTag: "rest"),
            Badge(name: "Ring Master",      description: "Close all 3 Faith Rings in one day",     icon: "circle.inset.filled",    categoryTag: "rings"),
            Badge(name: "Month of Faith",   description: "Maintain a 30-day streak",               icon: "calendar.badge.checkmark", categoryTag: "streak"),
            Badge(name: "Disciple Level",   description: "Reach the Disciple level",               icon: "book.fill",              categoryTag: "milestone"),
            Badge(name: "Century Club",     description: "Earn 100 total XP in a single day",      icon: "100.circle.fill",        categoryTag: "xp"),
        ]
    }
}
