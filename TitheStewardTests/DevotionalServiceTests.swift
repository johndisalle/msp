import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class DevotionalServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: DevotionalService!
    var profile: UserProfile!

    override func setUp() async throws {
        let schema = Schema([
            UserProfile.self, TitheRecord.self, BudgetCategory.self,
            BudgetTransaction.self, DebtItem.self, DebtPayment.self,
            DevotionalCompletion.self, GivingRecipient.self, RecurringGift.self, ChatSession.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        profile = UserProfile(displayName: "Test User", monthlyIncome: 5000)
        modelContext.insert(profile)
        try modelContext.save()

        service = DevotionalService(modelContext: modelContext)
    }

    // MARK: - Content Library

    func testDevotionalContentLibraryHas30Days() {
        XCTAssertEqual(DevotionalContentLibrary.devotionals.count, 30)
    }

    func testEachDevotionalHasUniqueDay() {
        let days = DevotionalContentLibrary.devotionals.map(\.dayOfCycle)
        let uniqueDays = Set(days)
        XCTAssertEqual(days.count, uniqueDays.count)
    }

    func testDevotionalDaysAre1Through30() {
        let days = DevotionalContentLibrary.devotionals.map(\.dayOfCycle).sorted()
        XCTAssertEqual(days, Array(1...30))
    }

    func testAllDevotionalsHaveContent() {
        for devotional in DevotionalContentLibrary.devotionals {
            XCTAssertFalse(devotional.title.isEmpty, "Day \(devotional.dayOfCycle) missing title")
            XCTAssertFalse(devotional.verse.isEmpty, "Day \(devotional.dayOfCycle) missing verse")
            XCTAssertFalse(devotional.verseReference.isEmpty, "Day \(devotional.dayOfCycle) missing reference")
            XCTAssertFalse(devotional.reflection.isEmpty, "Day \(devotional.dayOfCycle) missing reflection")
            XCTAssertFalse(devotional.prayerPrompt.isEmpty, "Day \(devotional.dayOfCycle) missing prayer")
        }
    }

    // MARK: - Today's Devotional

    func testLoadTodaysDevotional() {
        service.loadTodaysDevotional()
        XCTAssertNotNil(service.todaysDevotional)
    }

    func testTodaysDevotionalCyclesCorrectly() {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let expectedDay = ((dayOfYear - 1) % 30) + 1 // 1-indexed dayOfCycle

        service.loadTodaysDevotional()
        XCTAssertEqual(service.todaysDevotional?.dayOfCycle, expectedDay)
    }

    // MARK: - Completion Tracking

    func testMarkComplete() {
        service.markComplete(devotionalDay: 1, didPray: true, note: "Great reflection", profile: profile)

        XCTAssertEqual(profile.devotionalCompletions.count, 1)
        XCTAssertEqual(profile.devotionalCompletions.first?.devotionalDay, 1)
        XCTAssertTrue(profile.devotionalCompletions.first?.didPray ?? false)
        XCTAssertEqual(profile.devotionalCompletions.first?.personalNote, "Great reflection")
    }

    func testIsCompletedToday() {
        XCTAssertFalse(service.isCompletedToday(profile: profile))

        service.markComplete(devotionalDay: 1, didPray: true, profile: profile)
        XCTAssertTrue(service.isCompletedToday(profile: profile))
    }

    // MARK: - Streak Calculation

    func testDevotionalStreakZero() {
        let streak = service.devotionalStreak(profile: profile)
        XCTAssertEqual(streak, 0)
    }

    func testDevotionalStreakOneDay() {
        service.markComplete(devotionalDay: 1, didPray: true, profile: profile)

        let streak = service.devotionalStreak(profile: profile)
        XCTAssertEqual(streak, 1)
    }

    func testDevotionalStreakMultipleDays() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        // Add completions for 3 consecutive days
        let comp1 = DevotionalCompletion(devotionalDay: 1, date: twoDaysAgo, didPray: true)
        comp1.userProfile = profile
        profile.devotionalCompletions.append(comp1)
        modelContext.insert(comp1)

        let comp2 = DevotionalCompletion(devotionalDay: 2, date: yesterday, didPray: true)
        comp2.userProfile = profile
        profile.devotionalCompletions.append(comp2)
        modelContext.insert(comp2)

        let comp3 = DevotionalCompletion(devotionalDay: 3, date: today, didPray: true)
        comp3.userProfile = profile
        profile.devotionalCompletions.append(comp3)
        modelContext.insert(comp3)

        try? modelContext.save()

        let streak = service.devotionalStreak(profile: profile)
        XCTAssertEqual(streak, 3)
    }

    func testDevotionalStreakBrokenByGap() {
        let calendar = Calendar.current
        let today = Date()
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!

        // Completion 3 days ago (gap of 2 days)
        let oldComp = DevotionalCompletion(devotionalDay: 1, date: threeDaysAgo, didPray: true)
        oldComp.userProfile = profile
        profile.devotionalCompletions.append(oldComp)
        modelContext.insert(oldComp)

        // Completion today
        let todayComp = DevotionalCompletion(devotionalDay: 4, date: today, didPray: true)
        todayComp.userProfile = profile
        profile.devotionalCompletions.append(todayComp)
        modelContext.insert(todayComp)

        try? modelContext.save()

        let streak = service.devotionalStreak(profile: profile)
        // Should only count today (streak broken by gap)
        XCTAssertEqual(streak, 1)
    }

    // MARK: - All Devotionals

    func testAllDevotionals() {
        let all = service.allDevotionals
        XCTAssertEqual(all.count, 30)
    }
}
