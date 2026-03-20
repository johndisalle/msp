import XCTest
import SwiftData
@testable import TitheSteward

@MainActor
final class GivingPlanServiceTests: XCTestCase {
    var modelContext: ModelContext!
    var service: GivingPlanService!
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

        service = GivingPlanService(modelContext: modelContext)
    }

    // MARK: - Plan Generation

    func testPlanGeneratesPhases() {
        let plan = service.generatePlan(for: profile)
        XCTAssertFalse(plan.phases.isEmpty)
        XCTAssertGreaterThanOrEqual(plan.phases.count, 2, "Should have at least build-to-5% and generous-living phases")
    }

    func testPlanForNonGiverIncludesBuildPhases() {
        let plan = service.generatePlan(for: profile)
        XCTAssertEqual(plan.startingPercentage, 0, accuracy: 0.01)
        XCTAssertGreaterThan(plan.estimatedMonthsToFullTithe, 0)
        XCTAssertTrue(plan.phases.contains { $0.title.contains("5%") })
        XCTAssertTrue(plan.phases.contains { $0.title.contains("10%") })
    }

    func testPlanForFullTitherShowsGenerous() {
        // Give 10% = $500
        let record = TitheRecord(amount: 500, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let plan = service.generatePlan(for: profile)
        XCTAssertEqual(plan.estimatedMonthsToFullTithe, 0)
        XCTAssertTrue(plan.encouragement.contains("already tithing"))
    }

    func testPlanForPartialGiverShowsCorrectStart() {
        // Give 3% = $150
        let record = TitheRecord(amount: 150, category: .tithe, recipient: "Church")
        record.userProfile = profile
        profile.titheRecords.append(record)
        modelContext.insert(record)

        let plan = service.generatePlan(for: profile)
        XCTAssertEqual(plan.startingPercentage, 3, accuracy: 0.1)
    }

    func testPlanWithDebtIncludesStabilizePhase() {
        profile.hasDebt = true
        let debt = DebtItem(
            name: "Credit Card",
            originalBalance: 10000,
            currentBalance: 8000,
            interestRate: 18.0,
            minimumPayment: 200,
            type: .creditCard
        )
        debt.userProfile = profile
        profile.debts.append(debt)
        modelContext.insert(debt)

        let plan = service.generatePlan(for: profile)
        XCTAssertTrue(plan.phases.contains { $0.title.contains("Stabilize") })
    }

    func testPlanTargetAmountsMatchIncome() {
        let plan = service.generatePlan(for: profile)
        for phase in plan.phases {
            let expected = profile.monthlyIncome * Decimal(phase.targetPercentage) / 100
            XCTAssertEqual(phase.targetAmount, expected,
                "\(phase.title) target should be \(phase.targetPercentage)% of income")
        }
    }

    func testPlanCurrentPhaseMarked() {
        let plan = service.generatePlan(for: profile)
        let currentPhases = plan.phases.filter { $0.isCurrent }
        XCTAssertEqual(currentPhases.count, 1, "Exactly one phase should be current")
    }

    func testPlanPhaseActionsNonEmpty() {
        let plan = service.generatePlan(for: profile)
        for phase in plan.phases {
            XCTAssertFalse(phase.actions.isEmpty, "\(phase.title) should have actions")
            XCTAssertFalse(phase.milestoneVerse.isEmpty, "\(phase.title) should have a milestone verse")
        }
    }

    func testPlanAlwaysEndsWithGenerousLiving() {
        let plan = service.generatePlan(for: profile)
        XCTAssertEqual(plan.phases.last?.title, "Generous Living")
        XCTAssertEqual(plan.phases.last?.targetPercentage ?? 0, 15, accuracy: 0.1)
    }

    // MARK: - AI Prompt

    func testBuildPlanPromptContainsData() {
        let prompt = service.buildPlanPrompt(for: profile)
        XCTAssertTrue(prompt.contains("$5,000"))
        XCTAssertTrue(prompt.contains("Monthly income"))
    }
}
