// XPManager.swift
// FaithForge
//
// Manages XP awards, streak logic, Faith Ring progress, and badge unlocking.

import Foundation
import SwiftData
import Observation

@Observable
final class XPManager {
    private let modelContext: ModelContext

    /// Today's ring progress (3 entries).
    private(set) var todayRings: [FaithRingProgress] = []

    /// Optional challenge service to contribute XP to joined challenges.
    var challengeService: ChallengeService?

    /// Optional leaderboard service to sync profile after XP changes.
    var leaderboardService: LeaderboardService?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTodayRings()
    }

    // MARK: - Public API

    /// Award XP from completing a quest: updates profile, ring, streak, badges, challenges, leaderboard.
    func awardXP(amount: Int, questCategory: QuestCategory, profile: UserProfile) {
        // 1. Update total XP
        profile.totalXP += amount

        // 2. Update ring progress
        if let ring = questCategory.ringCategory {
            let ringProgress = todayRingProgress(for: ring)
            ringProgress.dailyXP += amount
        }

        // 3. Update streak
        updateStreak(profile: profile)

        // 4. Check badge unlocks
        checkBadgeUnlocks(profile: profile)

        // 5. Contribute XP to joined community challenges
        challengeService?.contributeXP(amount: amount, category: questCategory)

        // 6. Sync to leaderboard
        leaderboardService?.syncLocalProfile(profile, userID: profile.id.uuidString)

        try? modelContext.save()
        loadTodayRings()
    }

    /// Total XP earned today across all rings.
    var todayTotalXP: Int {
        todayRings.reduce(0) { $0 + $1.dailyXP }
    }

    /// Whether all 3 rings are fully closed today.
    var allRingsClosed: Bool {
        todayRings.allSatisfy { $0.fillFraction >= 1.0 }
    }

    /// Get today's ring progress for a specific ring.
    func ringProgress(for ring: RingCategory) -> FaithRingProgress {
        todayRingProgress(for: ring)
    }

    /// Reload ring data (call on day change).
    func refresh() {
        loadTodayRings()
    }

    // MARK: - Streak Logic

    private func updateStreak(profile: UserProfile) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let lastDate = profile.lastCompletionDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0

            if diff == 0 {
                // Already counted today — do nothing
            } else if diff == 1 {
                // Consecutive day
                profile.currentStreak += 1
            } else {
                // Streak broken, restart
                profile.currentStreak = 1
            }
        } else {
            // First ever completion
            profile.currentStreak = 1
        }

        profile.lastCompletionDate = Date()
        profile.longestStreak = max(profile.longestStreak, profile.currentStreak)
    }

    // MARK: - Ring Progress

    private func loadTodayRings() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<FaithRingProgress>(
            predicate: #Predicate<FaithRingProgress> {
                $0.date >= today && $0.date < tomorrow
            }
        )

        var rings = (try? modelContext.fetch(descriptor)) ?? []

        // Ensure all 3 ring categories exist for today
        for cat in RingCategory.allCases {
            if !rings.contains(where: { $0.ringCategoryRaw == cat.rawValue }) {
                let newRing = FaithRingProgress(ringCategory: cat, date: Date())
                modelContext.insert(newRing)
                rings.append(newRing)
            }
        }
        try? modelContext.save()
        todayRings = rings
    }

    private func todayRingProgress(for ring: RingCategory) -> FaithRingProgress {
        if let existing = todayRings.first(where: { $0.ringCategoryRaw == ring.rawValue }) {
            return existing
        }
        // Shouldn't happen after loadTodayRings, but safety fallback
        let newRing = FaithRingProgress(ringCategory: ring, date: Date())
        modelContext.insert(newRing)
        todayRings.append(newRing)
        return newRing
    }

    // MARK: - Badge Checking

    private func checkBadgeUnlocks(profile: UserProfile) {
        let descriptor = FetchDescriptor<Badge>(
            predicate: #Predicate<Badge> { !$0.isUnlocked }
        )
        guard let locked = try? modelContext.fetch(descriptor) else { return }

        for badge in locked {
            switch badge.name {
            case "First Step":
                badge.unlock()
            case "Week Warrior":
                if profile.currentStreak >= 7 { badge.unlock() }
            case "Month of Faith":
                if profile.currentStreak >= 30 { badge.unlock() }
            case "Ring Master":
                if allRingsClosed { badge.unlock() }
            case "Disciple Level":
                if profile.level == .disciple || profile.level == .apostle || profile.level == .shepherd {
                    badge.unlock()
                }
            case "Century Club":
                if todayTotalXP >= 100 { badge.unlock() }
            default:
                break // Other badges checked elsewhere or via category counts
            }
        }
    }

    // MARK: - Weekly XP History (for chart)

    /// Returns an array of (date, totalXP) for the last 7 days.
    func weeklyXPHistory() -> [(date: Date, xp: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var history: [(Date, Int)] = []

        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let nextDate = calendar.date(byAdding: .day, value: 1, to: date)!

            let descriptor = FetchDescriptor<FaithRingProgress>(
                predicate: #Predicate<FaithRingProgress> {
                    $0.date >= date && $0.date < nextDate
                }
            )
            let rings = (try? modelContext.fetch(descriptor)) ?? []
            let totalXP = rings.reduce(0) { $0 + $1.dailyXP }
            history.append((date, totalXP))
        }
        return history
    }
}
