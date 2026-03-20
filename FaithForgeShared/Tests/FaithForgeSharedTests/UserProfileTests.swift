// UserProfileTests.swift
// FaithForgeSharedTests

import Testing
@testable import FaithForgeShared

@Test func testFaithLevelProgression() {
    let profile = UserProfile(displayName: "Test")

    #expect(profile.level == .novice)
    #expect(profile.levelProgress == 0.0)

    profile.totalXP = 250
    #expect(profile.level == .novice)
    #expect(profile.levelProgress == 0.5)

    profile.totalXP = 500
    #expect(profile.level == .seeker)

    profile.totalXP = 2000
    #expect(profile.level == .disciple)

    profile.totalXP = 5000
    #expect(profile.level == .apostle)

    profile.totalXP = 12000
    #expect(profile.level == .shepherd)
    #expect(profile.levelProgress == 1.0)
    #expect(profile.xpToNextLevel == 0)
}

@Test func testXPToNextLevel() {
    let profile = UserProfile(displayName: "Test")
    profile.totalXP = 300
    // Novice threshold = 0, Seeker threshold = 500
    #expect(profile.xpToNextLevel == 200)
}

@Test func testDailyGoal() {
    let profile = UserProfile(displayName: "Test", dailyGoal: .devoted)
    #expect(profile.dailyGoal == .devoted)
    #expect(profile.dailyGoal.questCount == 7)

    profile.dailyGoal = .light
    #expect(profile.dailyGoalRaw == "Light")
    #expect(profile.dailyGoal.questCount == 3)
}

@Test func testRingProgress() {
    let ring = FaithRingProgress(ringCategory: .word)
    #expect(ring.fillFraction == 0.0)

    ring.dailyXP = 50
    #expect(ring.fillFraction == 0.5)

    ring.dailyXP = 150
    #expect(ring.fillFraction == 1.0) // Capped at 1.0
}

@Test func testBadgeSeedCount() {
    #expect(Badge.seedBadges.count == 10)
}

@Test func testBadgeUnlock() {
    let badge = Badge(name: "Test", description: "A test badge")
    #expect(!badge.isUnlocked)
    #expect(badge.unlockedDate == nil)

    badge.unlock()
    #expect(badge.isUnlocked)
    #expect(badge.unlockedDate != nil)

    // Double-unlock should be idempotent
    let firstDate = badge.unlockedDate
    badge.unlock()
    #expect(badge.unlockedDate == firstDate)
}

@Test func testTimerFormatting() {
    #expect(0.timerFormatted == "0:00")
    #expect(65.timerFormatted == "1:05")
    #expect(300.timerFormatted == "5:00")
    #expect(3661.timerFormatted == "61:01")
}

@Test func testVerseOfTheDay() {
    let verse = VerseOfTheDay.today
    #expect(!verse.text.isEmpty)
    #expect(!verse.reference.isEmpty)
    #expect(VerseOfTheDay.verses.count == 10)
}
