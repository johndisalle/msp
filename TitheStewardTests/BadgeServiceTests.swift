import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class BadgeServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: BadgeService!
    var profile: UserProfile!

    override func setUp() async throws {
        let schema = Schema([
            UserProfile.self, TitheRecord.self, BudgetCategory.self,
            BudgetTransaction.self, DebtItem.self, DebtPayment.self,
            DevotionalCompletion.self, GivingRecipient.self, RecurringGift.self, ChatSession.self, GenerosityBadge.self,
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        modelContext = container.mainContext

        profile = UserProfile(
            displayName: "Test User",
            monthlyIncome: 5000
        )
        modelContext.insert(profile)
        try modelContext.save()

        service = BadgeService(modelContext: modelContext)
    }

    // MARK: - First Gift Badge

    func testFirstGiftBadgeAwarded() {
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)

        XCTAssertTrue(badges.contains { $0.badgeType == .firstGift })
    }

    func testNoFirstGiftBadgeWithoutRecords() {
        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertFalse(badges.contains { $0.badgeType == .firstGift })
    }

    // MARK: - Full Tithe Badge

    func testFirstTitheBadgeAtTenPercent() {
        // 10% of 5000 = 500
        let record = TitheRecord(amount: 500, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .firstTithe })
    }

    func testNoTitheBadgeBelowTenPercent() {
        let record = TitheRecord(amount: 400, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertFalse(badges.contains { $0.badgeType == .firstTithe })
    }

    // MARK: - Level Badges

    func testJoyfulTitherBadge() {
        // 10-15% range = tither level
        let record = TitheRecord(amount: 500, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .joyfulTither })
    }

    func testGenerousHeartBadge() {
        // >15% of income
        let record = TitheRecord(amount: 800, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .generousHeart })
    }

    // MARK: - Streak Badges

    func testConsistentMonthBadge() {
        profile.generosityStreak = 1
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .consistentMonth })
    }

    func testQuarterStreakBadge() {
        profile.generosityStreak = 3
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .quarterStreak })
    }

    func testYearStreakBadge() {
        profile.generosityStreak = 12
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .yearStreak })
    }

    // MARK: - Recurring Gift Badge

    func testFirstRecurringBadge() {
        let recipient = GivingRecipient(name: "Church", type: .church)
        recipient.userProfile = profile
        profile.recipients.append(recipient)
        modelContext.insert(recipient)

        let gift = RecurringGift(amount: 500, frequency: .monthly, category: .tithe, isActive: true)
        gift.recipient = recipient
        recipient.recurringGifts.append(gift)
        modelContext.insert(gift)

        // Need at least one tithe record for firstGift
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .firstRecurring })
    }

    // MARK: - Multi-Ministry Badge

    func testMultiMinistryBadge() {
        let recipients = ["Church A", "Charity B", "Mission C"]
        for name in recipients {
            let record = TitheRecord(amount: 100, category: .tithe, recipient: name)
            record.userProfile = profile
            profile.titheRecords.append(record)
            modelContext.insert(record)
        }

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .multiMinistry })
    }

    func testNoMultiMinistryWithTwoRecipients() {
        for name in ["Church A", "Charity B"] {
            let record = TitheRecord(amount: 100, category: .tithe, recipient: name)
            record.userProfile = profile
            profile.titheRecords.append(record)
            modelContext.insert(record)
        }

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertFalse(badges.contains { $0.badgeType == .multiMinistry })
    }

    // MARK: - Giving Total Milestones

    func testThousandClubBadge() {
        profile.totalGivenAllTime = 1000
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .thousandClub })
    }

    func testFiveThousandClubBadge() {
        profile.totalGivenAllTime = 5000
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .fiveThousandClub })
    }

    func testTenThousandClubBadge() {
        profile.totalGivenAllTime = 10000
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(badges.contains { $0.badgeType == .tenThousandClub })
    }

    // MARK: - Idempotency

    func testBadgesNotDuplicated() {
        let record = TitheRecord(amount: 500, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let firstRun = service.evaluateAndAwardBadges(for: profile)
        XCTAssertFalse(firstRun.isEmpty)

        let secondRun = service.evaluateAndAwardBadges(for: profile)
        XCTAssertTrue(secondRun.isEmpty, "No new badges should be awarded on second evaluation")
    }

    // MARK: - Mark Seen

    func testMarkBadgeSeen() {
        let record = TitheRecord(amount: 50, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let badges = service.evaluateAndAwardBadges(for: profile)
        let badge = badges.first!
        XCTAssertTrue(badge.isNew)

        service.markBadgeSeen(badge)
        XCTAssertFalse(badge.isNew)
    }

    func testNewBadgeCount() {
        let record = TitheRecord(amount: 500, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        _ = service.evaluateAndAwardBadges(for: profile)
        let count = service.newBadgeCount(for: profile)
        XCTAssertGreaterThan(count, 0)

        // Mark all seen
        for badge in profile.badges {
            service.markBadgeSeen(badge)
        }
        XCTAssertEqual(service.newBadgeCount(for: profile), 0)
    }
}
