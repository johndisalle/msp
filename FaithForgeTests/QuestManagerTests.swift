// QuestManagerTests.swift
// FaithForgeTests
//
// Unit tests for QuestManager: quest generation, completion, day rollover.

import Testing
import Foundation
import SwiftData

@testable import FaithForge

// MARK: - QuestManager Tests

@Suite("QuestManager Tests")
struct QuestManagerTests {

    // Helper to create an in-memory model context for testing.
    private func makeContext() throws -> ModelContext {
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
        return ModelContext(container)
    }

    // MARK: - Quest Generation

    @Test("Generates 5 daily quests on first access")
    func generatesDailyQuests() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        #expect(manager.todaysQuests.count == 5)
    }

    @Test("Generated quests have valid properties")
    func questsHaveValidProperties() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        for quest in manager.todaysQuests {
            #expect(!quest.title.isEmpty)
            #expect(quest.xpReward > 0)
            #expect(!quest.isCompleted)
            #expect(quest.completedDate == nil)
        }
    }

    @Test("Quests are assigned to today's date")
    func questsAssignedToday() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let today = Calendar.current.startOfDay(for: Date())
        for quest in manager.todaysQuests {
            #expect(quest.assignedDate == today)
        }
    }

    @Test("Quests are sorted by sort order")
    func questsSortedBySortOrder() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let orders = manager.todaysQuests.map(\.sortOrder)
        #expect(orders == orders.sorted())
    }

    @Test("Refresh reloads existing quests, does not create duplicates")
    func refreshDoesNotDuplicate() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let firstCount = manager.todaysQuests.count
        manager.refresh()
        #expect(manager.todaysQuests.count == firstCount)
    }

    // MARK: - Quest Completion

    @Test("Completing a quest returns XP reward")
    func completeQuestReturnsXP() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let quest = manager.todaysQuests[0]
        let expectedXP = quest.xpReward
        let xp = manager.completeQuest(quest)

        #expect(xp == expectedXP)
    }

    @Test("Completing a quest marks it as completed")
    func completeQuestMarksCompleted() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let quest = manager.todaysQuests[0]
        _ = manager.completeQuest(quest)

        #expect(quest.isCompleted)
        #expect(quest.completedDate != nil)
    }

    @Test("Completing same quest twice returns 0 XP")
    func doubleCompleteReturnsZero() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let quest = manager.todaysQuests[0]
        _ = manager.completeQuest(quest)
        let secondXP = manager.completeQuest(quest)

        #expect(secondXP == 0)
    }

    @Test("Completed count updates after completion")
    func completedCountUpdates() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        #expect(manager.completedCount == 0)

        _ = manager.completeQuest(manager.todaysQuests[0])
        #expect(manager.completedCount == 1)

        _ = manager.completeQuest(manager.todaysQuests[1])
        #expect(manager.completedCount == 2)
    }

    @Test("allComplete is true when all quests done")
    func allCompleteWhenAllDone() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        #expect(!manager.allComplete)

        for quest in manager.todaysQuests {
            _ = manager.completeQuest(quest)
        }
        #expect(manager.allComplete)
    }

    @Test("Reflection text is saved on completion")
    func reflectionTextSaved() throws {
        let context = try makeContext()
        let manager = QuestManager(modelContext: context)

        let quest = manager.todaysQuests[0]
        _ = manager.completeQuest(quest, reflectionText: "God is good")

        #expect(quest.reflectionText == "God is good")
    }

    // MARK: - Sample Quest Data

    @Test("Sample quests pool has 20 entries")
    func sampleQuestCount() {
        #expect(QuestManager.sampleQuests.count == 20)
    }

    @Test("All four quest categories are represented in samples")
    func allCategoriesRepresented() {
        let categories = Set(QuestManager.sampleQuests.map(\.category))
        #expect(categories.contains(.theWord))
        #expect(categories.contains(.prayer))
        #expect(categories.contains(.mission))
        #expect(categories.contains(.restInGod))
    }

    @Test("All four quest types are represented in samples")
    func allTypesRepresented() {
        let types = Set(QuestManager.sampleQuests.map(\.type))
        #expect(types.contains(.timer))
        #expect(types.contains(.checkIn))
        #expect(types.contains(.reflection))
        #expect(types.contains(.quickLog))
    }

    @Test("Timer quests have positive durations")
    func timerQuestsHaveDurations() {
        let timerQuests = QuestManager.sampleQuests.filter { $0.type == .timer }
        for quest in timerQuests {
            #expect(quest.timerDuration > 0)
        }
    }

    @Test("Non-timer quests have zero duration")
    func nonTimerQuestsHaveZeroDuration() {
        let nonTimerQuests = QuestManager.sampleQuests.filter { $0.type != .timer }
        for quest in nonTimerQuests {
            #expect(quest.timerDuration == 0)
        }
    }
}
