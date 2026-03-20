import XCTest
@testable import TitheSteward

final class GenerosityScoreTests: XCTestCase {

    // MARK: - Monthly Percentage

    func testMonthlyPercentageBasic() {
        let score = GenerosityScore(
            totalGivenThisMonth: 500,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 500,
            annualIncome: 60000
        )
        XCTAssertEqual(score.monthlyPercentage, 10.0, accuracy: 0.01)
    }

    func testMonthlyPercentageZeroIncome() {
        let score = GenerosityScore(
            totalGivenThisMonth: 100,
            monthlyIncome: 0,
            currentStreak: 0,
            totalGivenThisYear: 100,
            annualIncome: 0
        )
        XCTAssertEqual(score.monthlyPercentage, 0)
    }

    func testMonthlyPercentagePartial() {
        let score = GenerosityScore(
            totalGivenThisMonth: 250,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 250,
            annualIncome: 60000
        )
        XCTAssertEqual(score.monthlyPercentage, 5.0, accuracy: 0.01)
    }

    // MARK: - Tithe Goal

    func testTitheGoalNotMet() {
        let score = GenerosityScore(
            totalGivenThisMonth: 400,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 400,
            annualIncome: 60000
        )
        XCTAssertFalse(score.titheGoalMet)
    }

    func testTitheGoalMet() {
        let score = GenerosityScore(
            totalGivenThisMonth: 500,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 500,
            annualIncome: 60000
        )
        XCTAssertTrue(score.titheGoalMet)
    }

    func testTitheGoalExceeded() {
        let score = GenerosityScore(
            totalGivenThisMonth: 750,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 750,
            annualIncome: 60000
        )
        XCTAssertTrue(score.titheGoalMet)
    }

    // MARK: - Remaining to Tithe

    func testRemainingToTithe() {
        let score = GenerosityScore(
            totalGivenThisMonth: 300,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 300,
            annualIncome: 60000
        )
        XCTAssertEqual(score.remainingToTithe, 200)
    }

    func testRemainingToTitheWhenExceeded() {
        let score = GenerosityScore(
            totalGivenThisMonth: 600,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 600,
            annualIncome: 60000
        )
        XCTAssertEqual(score.remainingToTithe, 0)
    }

    // MARK: - Progress to Tithe

    func testProgressToTitheHalf() {
        let score = GenerosityScore(
            totalGivenThisMonth: 250,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 250,
            annualIncome: 60000
        )
        XCTAssertEqual(score.progressToTithe, 0.5, accuracy: 0.01)
    }

    func testProgressToTitheCapsAtOne() {
        let score = GenerosityScore(
            totalGivenThisMonth: 1000,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 1000,
            annualIncome: 60000
        )
        XCTAssertEqual(score.progressToTithe, 1.0, accuracy: 0.01)
    }

    func testProgressToTitheZeroIncome() {
        let score = GenerosityScore(
            totalGivenThisMonth: 100,
            monthlyIncome: 0,
            currentStreak: 0,
            totalGivenThisYear: 100,
            annualIncome: 0
        )
        XCTAssertEqual(score.progressToTithe, 0)
    }

    // MARK: - Generosity Level

    func testLevelStarting() {
        let score = GenerosityScore(
            totalGivenThisMonth: 0,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 0,
            annualIncome: 60000
        )
        XCTAssertEqual(score.level, .starting)
    }

    func testLevelGrowing() {
        let score = GenerosityScore(
            totalGivenThisMonth: 100,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 100,
            annualIncome: 60000
        )
        // 2% → Growing Giver
        XCTAssertEqual(score.level, .growing)
    }

    func testLevelFaithful() {
        let score = GenerosityScore(
            totalGivenThisMonth: 350,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 350,
            annualIncome: 60000
        )
        // 7% → Faithful Steward
        XCTAssertEqual(score.level, .faithful)
    }

    func testLevelTither() {
        let score = GenerosityScore(
            totalGivenThisMonth: 500,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 500,
            annualIncome: 60000
        )
        // 10% → Joyful Tither
        XCTAssertEqual(score.level, .tither)
    }

    func testLevelGenerous() {
        let score = GenerosityScore(
            totalGivenThisMonth: 800,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 800,
            annualIncome: 60000
        )
        // 16% → Generous Heart
        XCTAssertEqual(score.level, .generous)
    }

    // MARK: - Annual Percentage

    func testAnnualPercentage() {
        let score = GenerosityScore(
            totalGivenThisMonth: 500,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 6000,
            annualIncome: 60000
        )
        XCTAssertEqual(score.annualPercentage, 10.0, accuracy: 0.01)
    }

    func testAnnualPercentageZeroIncome() {
        let score = GenerosityScore(
            totalGivenThisMonth: 0,
            monthlyIncome: 0,
            currentStreak: 0,
            totalGivenThisYear: 100,
            annualIncome: 0
        )
        XCTAssertEqual(score.annualPercentage, 0)
    }

    // MARK: - Monthly Tithe Target

    func testMonthlyTitheTarget() {
        let score = GenerosityScore(
            totalGivenThisMonth: 0,
            monthlyIncome: 5000,
            currentStreak: 0,
            totalGivenThisYear: 0,
            annualIncome: 60000
        )
        XCTAssertEqual(score.monthlyTitheTarget, 500)
    }
}
