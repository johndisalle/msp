// LeaderboardEntry.swift
// FaithForge
//
// Data model for leaderboard rankings. Synced via Firestore in production.

import Foundation
import SwiftData

/// Time window for leaderboard filtering.
enum LeaderboardPeriod: String, CaseIterable, Identifiable {
    case weekly  = "This Week"
    case monthly = "This Month"
    case allTime = "All Time"

    var id: String { rawValue }
}

@Model
final class LeaderboardEntry {
    var id: UUID = UUID()
    /// Remote user ID (Firebase UID or guest ID).
    var userID: String = ""
    var displayName: String = ""
    var totalXP: Int = 0
    var weeklyXP: Int = 0
    var monthlyXP: Int = 0
    var currentStreak: Int = 0
    var levelRaw: String = FaithLevel.novice.rawValue
    /// Profile avatar SF Symbol name.
    var avatarSymbol: String = "person.crop.circle.fill"
    /// Whether this is the local user's own entry.
    var isCurrentUser: Bool = false
    var lastSyncDate: Date = Date()

    init(
        userID: String,
        displayName: String,
        totalXP: Int = 0,
        weeklyXP: Int = 0,
        monthlyXP: Int = 0,
        currentStreak: Int = 0,
        level: FaithLevel = .novice,
        avatarSymbol: String = "person.crop.circle.fill",
        isCurrentUser: Bool = false
    ) {
        self.id = UUID()
        self.userID = userID
        self.displayName = displayName
        self.totalXP = totalXP
        self.weeklyXP = weeklyXP
        self.monthlyXP = monthlyXP
        self.currentStreak = currentStreak
        self.levelRaw = level.rawValue
        self.avatarSymbol = avatarSymbol
        self.isCurrentUser = isCurrentUser
        self.lastSyncDate = Date()
    }

    var level: FaithLevel {
        FaithLevel(rawValue: levelRaw) ?? .novice
    }

    /// XP value for a given period.
    func xp(for period: LeaderboardPeriod) -> Int {
        switch period {
        case .weekly:  return weeklyXP
        case .monthly: return monthlyXP
        case .allTime: return totalXP
        }
    }
}
