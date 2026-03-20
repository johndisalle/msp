// QuestManager.swift
// FaithForge
//
// Manages daily quest generation, completion, and persistence via SwiftData.

import Foundation
import SwiftData
import Observation

@Observable
final class QuestManager {
    private let modelContext: ModelContext

    /// Today's quests, refreshed on access.
    private(set) var todaysQuests: [DailyQuest] = []

    /// Optional AI service for personalized quest generation.
    var aiService: AIQuestService?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrGenerateTodaysQuests()
    }

    // MARK: - Public API

    /// Reload quests for today. Called on app foreground / day change.
    func refresh() {
        loadOrGenerateTodaysQuests()
    }

    /// Generate AI quests for today, replacing any unstarted hardcoded quests.
    func generateAIQuests(profile: UserProfile) async {
        guard let aiService else { return }

        let templates = await aiService.generateQuests(
            profile: profile,
            count: profile.dailyGoal.questCount,
            existingQuests: todaysQuests
        )

        await MainActor.run {
            // Remove uncompleted quests from today
            for quest in todaysQuests where !quest.isCompleted {
                modelContext.delete(quest)
            }

            // Insert AI-generated quests
            let completedCount = todaysQuests.filter(\.isCompleted).count
            for (i, template) in templates.enumerated() {
                let quest = DailyQuest(
                    title: template.title,
                    description: template.description,
                    category: template.category,
                    type: template.type,
                    xpReward: template.xpReward,
                    timerDuration: template.timerDuration,
                    sortOrder: completedCount + i
                )
                modelContext.insert(quest)
            }
            try? modelContext.save()
            loadOrGenerateTodaysQuests()
        }
    }

    /// Mark a quest as completed, persist, and return XP earned.
    @discardableResult
    func completeQuest(_ quest: DailyQuest, reflectionText: String = "") -> Int {
        guard !quest.isCompleted else { return 0 }
        quest.isCompleted = true
        quest.completedDate = Date()
        if !reflectionText.isEmpty {
            quest.reflectionText = reflectionText
        }
        try? modelContext.save()
        // Reload to update ordering
        loadOrGenerateTodaysQuests()
        return quest.xpReward
    }

    /// Number of quests completed today.
    var completedCount: Int {
        todaysQuests.filter(\.isCompleted).count
    }

    /// Whether all of today's quests are done.
    var allComplete: Bool {
        !todaysQuests.isEmpty && todaysQuests.allSatisfy(\.isCompleted)
    }

    // MARK: - Private

    private func loadOrGenerateTodaysQuests() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!

        let descriptor = FetchDescriptor<DailyQuest>(
            predicate: #Predicate<DailyQuest> {
                $0.assignedDate >= startOfDay && $0.assignedDate < endOfDay
            },
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        if let existing = try? modelContext.fetch(descriptor), !existing.isEmpty {
            todaysQuests = existing
            return
        }

        // First time today — generate from seed quests (AI override handled by generateAIQuests)
        let seeds = Self.sampleQuests.shuffled().prefix(5)
        for (i, template) in seeds.enumerated() {
            let quest = DailyQuest(
                title: template.title,
                description: template.description,
                category: template.category,
                type: template.type,
                xpReward: template.xpReward,
                timerDuration: template.timerDuration,
                sortOrder: i
            )
            modelContext.insert(quest)
        }
        try? modelContext.save()

        // Re-fetch to populate
        todaysQuests = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - 20 Hardcoded Sample Quests

    struct QuestTemplate {
        let title: String
        let description: String
        let category: QuestCategory
        let type: QuestType
        let xpReward: Int
        let timerDuration: Int
    }

    static let sampleQuests: [QuestTemplate] = [
        // The Word
        QuestTemplate(title: "Read a Psalm",           description: "Open your Bible and read one Psalm slowly.",                 category: .theWord, type: .checkIn,    xpReward: 30, timerDuration: 0),
        QuestTemplate(title: "Memorize a Verse",       description: "Choose one verse and commit it to memory today.",            category: .theWord, type: .reflection, xpReward: 40, timerDuration: 0),
        QuestTemplate(title: "Gospel Chapter",          description: "Read one full chapter from a Gospel (Matthew–John).",        category: .theWord, type: .checkIn,    xpReward: 35, timerDuration: 0),
        QuestTemplate(title: "Proverbs Wisdom",        description: "Read the Proverb for today's date.",                        category: .theWord, type: .checkIn,    xpReward: 25, timerDuration: 0),
        QuestTemplate(title: "Scripture Reflection",    description: "Write 2-3 sentences about what God showed you today.",       category: .theWord, type: .reflection, xpReward: 45, timerDuration: 0),

        // Prayer
        QuestTemplate(title: "Morning Prayer",         description: "Spend 5 minutes in prayer to start your day.",              category: .prayer, type: .timer,      xpReward: 30, timerDuration: 300),
        QuestTemplate(title: "Gratitude Prayer",       description: "Name 5 things you're thankful for in prayer.",              category: .prayer, type: .reflection, xpReward: 25, timerDuration: 0),
        QuestTemplate(title: "Intercessory Prayer",    description: "Pray for 3 people by name for 5 minutes.",                  category: .prayer, type: .timer,      xpReward: 35, timerDuration: 300),
        QuestTemplate(title: "Quiet Listening",        description: "Sit in silence for 3 minutes, listening for God's voice.",   category: .prayer, type: .timer,      xpReward: 30, timerDuration: 180),
        QuestTemplate(title: "Praise & Worship",       description: "Spend 5 minutes in praise and worship.",                    category: .prayer, type: .timer,      xpReward: 30, timerDuration: 300),

        // Mission / Action
        QuestTemplate(title: "Encourage Someone",      description: "Send an encouraging text or message to a friend.",          category: .mission, type: .quickLog,   xpReward: 20, timerDuration: 0),
        QuestTemplate(title: "Random Act of Kindness", description: "Do one unexpected kind thing for someone today.",            category: .mission, type: .quickLog,   xpReward: 25, timerDuration: 0),
        QuestTemplate(title: "Give Generously",        description: "Give financially or materially to someone in need.",        category: .mission, type: .quickLog,   xpReward: 35, timerDuration: 0),
        QuestTemplate(title: "Share Your Faith",       description: "Have a conversation about your faith with someone.",        category: .mission, type: .checkIn,    xpReward: 50, timerDuration: 0),
        QuestTemplate(title: "Serve Your Community",   description: "Volunteer time or help a neighbor with a task.",            category: .mission, type: .checkIn,    xpReward: 40, timerDuration: 0),

        // Rest in God
        QuestTemplate(title: "Digital Sabbath",        description: "Take a 30-minute break from all screens.",                  category: .restInGod, type: .timer,     xpReward: 30, timerDuration: 1800),
        QuestTemplate(title: "Nature Walk",            description: "Walk outside for 15 minutes appreciating God's creation.",  category: .restInGod, type: .timer,     xpReward: 25, timerDuration: 900),
        QuestTemplate(title: "Mindful Breathing",      description: "Practice 3 minutes of slow, prayerful breathing.",          category: .restInGod, type: .timer,     xpReward: 20, timerDuration: 180),
        QuestTemplate(title: "Rest Reflection",        description: "Journal about how God has given you rest this week.",        category: .restInGod, type: .reflection, xpReward: 30, timerDuration: 0),
        QuestTemplate(title: "Sleep Well",             description: "Get 7+ hours of sleep tonight (logged via HealthKit).",     category: .restInGod, type: .checkIn,   xpReward: 25, timerDuration: 0),
    ]
}
