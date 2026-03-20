// XPManagerTests.swift
// FaithForgeTests
//
// Unit tests for XPManager: XP awards, streak logic, ring progress, badge unlocking.

import Testing
import Foundation
import SwiftData

@testable import FaithForge

// MARK: - XPManager Tests

@Suite("XPManager Tests")
struct XPManagerTests {

    // Helper to create in-memory context with a profile and seed badges.
    private func makeContext() throws -> (ModelContext, UserProfile) {
        let schema = Schema([
            UserProfile.self,
            DailyQuest.self,
            Badge.self,
            FaithRingProgress.self,
            LeaderboardEntry.self,
            FriendConnection.self,
            CommunityChallenge.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let context = ModelContext(container)

        let profile = UserProfile(displayName: "Test User")
        context.insert(profile)

        // Seed badges for unlock tests
        let badgeNames = [
            "First Step", "Week Warrior", "Month of Faith", "Ring Master",
            "Disciple Level", "Century Club", "Word Warrior", "Prayer Pillar",
            "Mission Maven", "Social Butterfly",
        ]
        for name in badgeNames {
            let badge = Badge(name: name, badgeDescription: "Test badge", icon: "star.fill")
            context.insert(badge)
        }

        try context.save()
        return (context, profile)
    }

    // MARK: - XP Awards

    @Test("Award XP increases total XP")
    func awardXPIncreasesTotal() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        #expect(profile.totalXP == 30)
    }

    @Test("Multiple XP awards accumulate")
    func multipleAwardsAccumulate() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 25, questCategory: .prayer, profile: profile)
        manager.awardXP(amount: 20, questCategory: .mission, profile: profile)

        #expect(profile.totalXP == 75)
    }

    // MARK: - Ring Progress

    @Test("XP updates corresponding ring")
    func xpUpdatesRing() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 50, questCategory: .theWord, profile: profile)

        let wordRing = manager.ringProgress(for: .word)
        #expect(wordRing.dailyXP == 50)
    }

    @Test("Different categories update different rings")
    func differentCategoriesUpdateDifferentRings() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 25, questCategory: .prayer, profile: profile)
        manager.awardXP(amount: 20, questCategory: .mission, profile: profile)

        #expect(manager.ringProgress(for: .word).dailyXP == 30)
        #expect(manager.ringProgress(for: .communion).dailyXP == 25)
        #expect(manager.ringProgress(for: .mission).dailyXP == 20)
    }

    @Test("Rest in God category does not update any ring")
    func restInGodNoRing() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .restInGod, profile: profile)

        // All rings should still be 0
        for ring in RingCategory.allCases {
            #expect(manager.ringProgress(for: ring).dailyXP == 0)
        }
    }

    @Test("Today total XP sums all rings")
    func todayTotalXPSumsAllRings() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 25, questCategory: .prayer, profile: profile)
        manager.awardXP(amount: 20, questCategory: .mission, profile: profile)

        #expect(manager.todayTotalXP == 75)
    }

    @Test("All rings closed when each ring meets daily goal")
    func allRingsClosedWhenGoalsMet() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        // Word: 100, Communion: 80, Mission: 60
        manager.awardXP(amount: 100, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 80, questCategory: .prayer, profile: profile)
        manager.awardXP(amount: 60, questCategory: .mission, profile: profile)

        #expect(manager.allRingsClosed)
    }

    @Test("All rings not closed when some ring is short")
    func allRingsNotClosedWhenShort() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 100, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 80, questCategory: .prayer, profile: profile)
        manager.awardXP(amount: 10, questCategory: .mission, profile: profile)

        #expect(!manager.allRingsClosed)
    }

    // MARK: - Streak Logic

    @Test("First completion sets streak to 1")
    func firstCompletionSetsStreak() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        #expect(profile.currentStreak == 0)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        #expect(profile.currentStreak == 1)
    }

    @Test("Multiple completions same day keep streak at 1")
    func sameDayKeepsStreak() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 25, questCategory: .prayer, profile: profile)

        #expect(profile.currentStreak == 1)
    }

    @Test("Longest streak is always >= current streak")
    func longestStreakAtLeastCurrent() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        #expect(profile.longestStreak >= profile.currentStreak)
    }

    @Test("Last completion date is set after award")
    func lastCompletionDateSet() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        #expect(profile.lastCompletionDate == nil)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        #expect(profile.lastCompletionDate != nil)
    }

    // MARK: - Badge Unlocking

    @Test("First Step badge unlocks on first XP award")
    func firstStepBadgeUnlocks() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)

        let descriptor = FetchDescriptor<Badge>(
            predicate: #Predicate<Badge> { $0.name == "First Step" }
        )
        let badge = try context.fetch(descriptor).first
        #expect(badge?.isUnlocked == true)
    }

    @Test("Century Club badge unlocks at 100 daily XP")
    func centuryClubBadgeUnlocks() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        // Award 100 XP total across rings today
        manager.awardXP(amount: 50, questCategory: .theWord, profile: profile)
        manager.awardXP(amount: 50, questCategory: .prayer, profile: profile)

        let descriptor = FetchDescriptor<Badge>(
            predicate: #Predicate<Badge> { $0.name == "Century Club" }
        )
        let badge = try context.fetch(descriptor).first
        #expect(badge?.isUnlocked == true)
    }

    @Test("Disciple Level badge unlocks at level Disciple")
    func discipleLevelBadgeUnlocks() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        // Disciple requires 2000 XP - award in chunks
        for _ in 0..<67 {
            manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        }

        #expect(profile.totalXP >= 2000)
        #expect(profile.level == .disciple || profile.level == .apostle || profile.level == .shepherd)

        let descriptor = FetchDescriptor<Badge>(
            predicate: #Predicate<Badge> { $0.name == "Disciple Level" }
        )
        let badge = try context.fetch(descriptor).first
        #expect(badge?.isUnlocked == true)
    }

    // MARK: - Level Progression

    @Test("User starts at Novice level")
    func startsAtNovice() throws {
        let (_, profile) = try makeContext()
        #expect(profile.level == .novice)
    }

    @Test("Reaching 500 XP promotes to Seeker")
    func seekerAt500() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        for _ in 0..<17 {
            manager.awardXP(amount: 30, questCategory: .theWord, profile: profile)
        }

        #expect(profile.totalXP >= 500)
        #expect(profile.level == .seeker)
    }

    @Test("Level progress is between 0 and 1")
    func levelProgressBounded() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        manager.awardXP(amount: 250, questCategory: .theWord, profile: profile)

        #expect(profile.levelProgress >= 0.0)
        #expect(profile.levelProgress <= 1.0)
    }

    @Test("XP to next level decreases as XP increases")
    func xpToNextLevelDecreases() throws {
        let (context, profile) = try makeContext()
        let manager = XPManager(modelContext: context)

        let initialToNext = profile.xpToNextLevel
        manager.awardXP(amount: 100, questCategory: .theWord, profile: profile)

        #expect(profile.xpToNextLevel < initialToNext)
    }

    // MARK: - Weekly History

    @Test("Weekly XP history returns 7 entries")
    func weeklyHistoryCount() throws {
        let (context, _) = try makeContext()
        let manager = XPManager(modelContext: context)

        let history = manager.weeklyXPHistory()
        #expect(history.count == 7)
    }

    @Test("Weekly XP history dates are in order")
    func weeklyHistoryDatesOrdered() throws {
        let (context, _) = try makeContext()
        let manager = XPManager(modelContext: context)

        let history = manager.weeklyXPHistory()
        for i in 1..<history.count {
            #expect(history[i].date >= history[i - 1].date)
        }
    }
}
