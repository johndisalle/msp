import Foundation
import SwiftUI
import SwiftData

// MARK: - Badge Definitions

struct AchievementBadge: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let color: Color
    let category: BadgeCategory
    let requirement: Int

    enum BadgeCategory: String, CaseIterable {
        case journey = "Journey"
        case prayer = "Prayer"
        case scripture = "Scripture"
        case streak = "Streak"
        case journal = "Journal"
        case special = "Special"

        var icon: String {
            switch self {
            case .journey: return "map.fill"
            case .prayer: return "hands.sparkles.fill"
            case .scripture: return "book.fill"
            case .streak: return "flame.fill"
            case .journal: return "pencil.and.outline"
            case .special: return "star.fill"
            }
        }
    }
}

// MARK: - Badge Catalog

enum BadgeCatalog {
    static let all: [AchievementBadge] = [
        // Journey milestones
        AchievementBadge(id: "first_step", name: "First Step", description: "Complete your first day", icon: "figure.walk", color: .green, category: .journey, requirement: 1),
        AchievementBadge(id: "week_one", name: "First 7 Days", description: "Complete 7 days of a journey", icon: "7.circle.fill", color: .blue, category: .journey, requirement: 7),
        AchievementBadge(id: "halfway", name: "Halfway There", description: "Complete 20 days of a journey", icon: "flag.fill", color: .orange, category: .journey, requirement: 20),
        AchievementBadge(id: "finisher", name: "Journey Complete", description: "Finish an entire 40-day journey", icon: "trophy.fill", color: .yellow, category: .journey, requirement: 40),
        AchievementBadge(id: "two_journeys", name: "Double Down", description: "Complete 2 journeys", icon: "repeat.circle.fill", color: .purple, category: .journey, requirement: 2),

        // Prayer
        AchievementBadge(id: "prayer_starter", name: "Prayer Starter", description: "Pray 3 days", icon: "hands.sparkles", color: .blue, category: .prayer, requirement: 3),
        AchievementBadge(id: "prayer_faithful", name: "Faithful in Prayer", description: "Pray 14 days", icon: "hands.sparkles.fill", color: .indigo, category: .prayer, requirement: 14),
        AchievementBadge(id: "prayer_warrior", name: "Prayer Warrior", description: "Pray 30 days", icon: "shield.fill", color: .purple, category: .prayer, requirement: 30),

        // Scripture Memory
        AchievementBadge(id: "memory_first", name: "Hidden in My Heart", description: "Save your first verse to memorize", icon: "brain.head.profile", color: .teal, category: .scripture, requirement: 1),
        AchievementBadge(id: "memory_five", name: "Growing Library", description: "Save 5 verses to memorize", icon: "books.vertical.fill", color: .cyan, category: .scripture, requirement: 5),
        AchievementBadge(id: "memory_master", name: "Memory Master", description: "Fully memorize 10 verses", icon: "graduationcap.fill", color: .mint, category: .scripture, requirement: 10),

        // Streak
        AchievementBadge(id: "streak_3", name: "Getting Started", description: "3-day streak", icon: "flame", color: .orange, category: .streak, requirement: 3),
        AchievementBadge(id: "streak_7", name: "On Fire", description: "7-day streak", icon: "flame.fill", color: .orange, category: .streak, requirement: 7),
        AchievementBadge(id: "streak_14", name: "Unstoppable", description: "14-day streak", icon: "bolt.fill", color: .red, category: .streak, requirement: 14),
        AchievementBadge(id: "streak_30", name: "Unshakeable", description: "30-day streak", icon: "mountain.2.fill", color: .brown, category: .streak, requirement: 30),

        // Journal
        AchievementBadge(id: "journal_first", name: "Dear Diary", description: "Write your first journal entry", icon: "pencil.line", color: .pink, category: .journal, requirement: 1),
        AchievementBadge(id: "journal_10", name: "Reflective Soul", description: "Write 10 journal entries", icon: "text.book.closed.fill", color: .pink, category: .journal, requirement: 10),
        AchievementBadge(id: "journal_30", name: "Faithful Scribe", description: "Write 30 journal entries", icon: "pencil.and.outline", color: .red, category: .journal, requirement: 30),

        // Special
        AchievementBadge(id: "early_bird", name: "Early Bird", description: "Complete a day before 7 AM", icon: "sunrise.fill", color: .orange, category: .special, requirement: 1),
        AchievementBadge(id: "night_owl", name: "Night Owl", description: "Complete a day after 10 PM", icon: "moon.stars.fill", color: .indigo, category: .special, requirement: 1),
        AchievementBadge(id: "share_verse", name: "Light Bearer", description: "Share a verse with someone", icon: "square.and.arrow.up", color: .yellow, category: .special, requirement: 1),
        AchievementBadge(id: "all_steps", name: "Doer of the Word", description: "Complete all action steps in a day", icon: "checkmark.seal.fill", color: .green, category: .special, requirement: 1),
    ]

    static func badge(for id: String) -> AchievementBadge? {
        all.first { $0.id == id }
    }
}

// MARK: - Achievement Service

final class AchievementService {
    static let shared = AchievementService()

    private let defaults = UserDefaults.standard
    private let earnedKey = "earnedBadgeIDs"
    private let newBadgesKey = "newUnseenBadgeIDs"

    private init() {}

    var earnedBadgeIDs: Set<String> {
        get { Set(defaults.stringArray(forKey: earnedKey) ?? []) }
        set { defaults.set(Array(newValue), forKey: earnedKey) }
    }

    var unseenBadgeIDs: [String] {
        get { defaults.stringArray(forKey: newBadgesKey) ?? [] }
        set { defaults.set(newValue, forKey: newBadgesKey) }
    }

    func markSeen(_ badgeID: String) {
        unseenBadgeIDs.removeAll { $0 == badgeID }
    }

    func markAllSeen() {
        unseenBadgeIDs = []
    }

    /// Check all badges and return any newly earned ones.
    @discardableResult
    func evaluate(journeys: [Journey], journalEntryCount: Int) -> [AchievementBadge] {
        var newlyEarned: [AchievementBadge] = []
        var earned = earnedBadgeIDs

        let allDays = journeys.flatMap { $0.days ?? [] }
        let completedDays = allDays.filter { $0.isCompleted }
        let totalCompleted = completedDays.count
        let prayedDays = completedDays.filter { $0.hasPrayed }.count
        let completedJourneys = journeys.filter { $0.isCompleted }.count
        let memoryVerses = ScriptureMemoryService.shared.loadVerses()
        let memorizedCount = memoryVerses.filter { $0.masteryLevel == .memorized }.count
        let savedVerseCount = memoryVerses.count

        // Best streak across all journeys
        let bestStreak = journeys.map { StreakService.shared.calculateStreak(for: $0).longestStreak }.max() ?? 0

        for badge in BadgeCatalog.all {
            guard !earned.contains(badge.id) else { continue }

            let qualifies: Bool
            switch badge.id {
            // Journey
            case "first_step": qualifies = totalCompleted >= 1
            case "week_one": qualifies = totalCompleted >= 7
            case "halfway": qualifies = totalCompleted >= 20
            case "finisher": qualifies = completedJourneys >= 1
            case "two_journeys": qualifies = completedJourneys >= 2

            // Prayer
            case "prayer_starter": qualifies = prayedDays >= 3
            case "prayer_faithful": qualifies = prayedDays >= 14
            case "prayer_warrior": qualifies = prayedDays >= 30

            // Scripture
            case "memory_first": qualifies = savedVerseCount >= 1
            case "memory_five": qualifies = savedVerseCount >= 5
            case "memory_master": qualifies = memorizedCount >= 10

            // Streak
            case "streak_3": qualifies = bestStreak >= 3
            case "streak_7": qualifies = bestStreak >= 7
            case "streak_14": qualifies = bestStreak >= 14
            case "streak_30": qualifies = bestStreak >= 30

            // Journal
            case "journal_first": qualifies = journalEntryCount >= 1
            case "journal_10": qualifies = journalEntryCount >= 10
            case "journal_30": qualifies = journalEntryCount >= 30

            // Special — time-based
            case "early_bird":
                qualifies = completedDays.contains { day in
                    guard let date = day.date else { return false }
                    return Calendar.current.component(.hour, from: date) < 7
                }
            case "night_owl":
                qualifies = completedDays.contains { day in
                    guard let date = day.date else { return false }
                    return Calendar.current.component(.hour, from: date) >= 22
                }
            case "all_steps":
                qualifies = completedDays.contains { day in
                    !day.actionSteps.isEmpty && day.actionSteps.allSatisfy(\.isCompleted)
                }
            case "share_verse":
                qualifies = defaults.bool(forKey: "hasSharedVerse")

            default: qualifies = false
            }

            if qualifies {
                earned.insert(badge.id)
                newlyEarned.append(badge)
            }
        }

        if !newlyEarned.isEmpty {
            earnedBadgeIDs = earned
            unseenBadgeIDs += newlyEarned.map(\.id)
        }

        return newlyEarned
    }

    /// Call when user shares a verse to unlock the badge.
    func recordVerseShare() {
        defaults.set(true, forKey: "hasSharedVerse")
    }
}
