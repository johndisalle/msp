import Foundation
import SwiftData

/// AI-powered personalized giving plan that analyzes income, debt, expenses,
/// and builds a phased plan toward full tithe.
@MainActor
class GivingPlanService {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    struct GivingPlan {
        let phases: [Phase]
        let currentPhaseIndex: Int
        let estimatedMonthsToFullTithe: Int
        let startingPercentage: Double
        let targetPercentage: Double
        let encouragement: String
        let verse: String
    }

    struct Phase: Identifiable {
        let id = UUID()
        let monthRange: String
        let title: String
        let description: String
        let targetPercentage: Double
        let targetAmount: Decimal
        let actions: [String]
        let milestoneVerse: String
        let isComplete: Bool
        let isCurrent: Bool
    }

    func generatePlan(for profile: UserProfile) -> GivingPlan {
        let titheService = TitheCalculatorService(modelContext: modelContext)
        let debtService = DebtService(modelContext: modelContext)
        let budgetService = BudgetService(modelContext: modelContext)

        let score = titheService.calculateGenerosityScore(for: profile)
        let debts = debtService.fetchDebts()
        let categories = budgetService.fetchCategories()

        let income = profile.monthlyIncome
        let currentGiving = score.totalGivenThisMonth
        let currentPercent = income > 0 ? NSDecimalNumber(decimal: currentGiving / income * 100).doubleValue : 0
        let hasDebt = !debts.isEmpty
        let totalDebt = debtService.totalDebt(debts)
        let minimumPayments = debtService.totalMinimumPayments(debts)
        let totalBudgeted = budgetService.totalBudgeted(categories)

        // Calculate available margin
        let essentials = totalBudgeted > 0 ? totalBudgeted : income * Decimal(string: "0.70")!
        let disposable = income - essentials - minimumPayments

        var phases: [Phase] = []
        var monthCounter = 1

        // Phase 1: Stabilize (if in debt or no budget)
        if hasDebt && totalDebt > minimumPayments * 6 {
            let stabilizeEnd = min(3, max(1, Int(ceil(NSDecimalNumber(decimal: totalDebt / (minimumPayments * 12)).doubleValue))))
            let stabilizeMonths = "\(monthCounter)-\(monthCounter + stabilizeEnd - 1)"
            let startPercent = max(1, min(currentPercent, 3))

            phases.append(Phase(
                monthRange: "Month \(stabilizeMonths)",
                title: "Stabilize & Start Giving",
                description: "Focus on meeting minimum debt payments while starting a small, consistent giving habit. Even 1-3% builds the muscle of generosity.",
                targetPercentage: startPercent,
                targetAmount: income * Decimal(startPercent) / 100,
                actions: [
                    "Set up a recurring gift of \((income * Decimal(startPercent) / 100).currencyFormatted)/month",
                    "Pay all minimum debt payments (\(minimumPayments.currencyFormatted)/month)",
                    "Track every expense for 30 days to find savings",
                    "Read Proverbs 22:7 — commit to debt freedom"
                ],
                milestoneVerse: "\"The borrower is slave to the lender.\" — Proverbs 22:7",
                isComplete: currentPercent >= startPercent && profile.generosityStreak >= stabilizeEnd,
                isCurrent: currentPercent < startPercent
            ))
            monthCounter += stabilizeEnd
        }

        // Phase 2: Build to 5%
        if currentPercent < 5 {
            let buildMonths = hasDebt ? 3 : 2
            phases.append(Phase(
                monthRange: "Month \(monthCounter)-\(monthCounter + buildMonths - 1)",
                title: "Build to 5%",
                description: "Increase giving to 5% of income. This is halfway to a full tithe and builds confidence in God's provision.",
                targetPercentage: 5,
                targetAmount: income * Decimal(string: "0.05")!,
                actions: [
                    "Increase recurring gift to \((income * Decimal(string: "0.05")!).currencyFormatted)/month",
                    "Cut one discretionary expense to fund the increase",
                    "Start a 7-day stewardship devotional",
                    hasDebt ? "Apply debt snowball method to smallest debt" : "Build a 1-month emergency buffer"
                ],
                milestoneVerse: "\"Whoever sows sparingly will also reap sparingly.\" — 2 Corinthians 9:6",
                isComplete: currentPercent >= 5,
                isCurrent: currentPercent >= (phases.isEmpty ? 0 : phases.last!.targetPercentage) && currentPercent < 5
            ))
            monthCounter += buildMonths
        }

        // Phase 3: Reach full tithe
        if currentPercent < 10 {
            let titheMonths = hasDebt ? 4 : 2
            phases.append(Phase(
                monthRange: "Month \(monthCounter)-\(monthCounter + titheMonths - 1)",
                title: "Reach Full Tithe (10%)",
                description: "The moment of faithful obedience — bringing the whole tithe into the storehouse. Trust God's promise to open the floodgates of heaven.",
                targetPercentage: 10,
                targetAmount: income * Decimal(string: "0.10")!,
                actions: [
                    "Increase recurring gift to \((income * Decimal(string: "0.10")!).currencyFormatted)/month",
                    "Set up tithe as the first 'bill' on payday",
                    "Journal God's provision — write down how He provides",
                    "Share your tithe commitment with an accountability partner"
                ],
                milestoneVerse: "\"Bring the whole tithe into the storehouse... Test me in this, if I will not throw open the floodgates of heaven.\" — Malachi 3:10",
                isComplete: currentPercent >= 10,
                isCurrent: currentPercent >= 5 && currentPercent < 10
            ))
            monthCounter += titheMonths
        }

        // Phase 4: Beyond the tithe (generosity)
        phases.append(Phase(
            monthRange: "Month \(monthCounter)+",
            title: "Generous Living",
            description: "You've reached the tithe! Now grow in radical generosity — offerings, missions, and spontaneous giving that overflows from a grateful heart.",
            targetPercentage: 15,
            targetAmount: income * Decimal(string: "0.15")!,
            actions: [
                "Maintain your tithe and add offerings above 10%",
                "Support a missionary or sponsored child monthly",
                "Look for spontaneous giving opportunities weekly",
                hasDebt ? "Accelerate debt payoff with freed-up margin" : "Give to a new ministry or cause each quarter"
            ],
            milestoneVerse: "\"God loves a cheerful giver.\" — 2 Corinthians 9:7",
            isComplete: currentPercent >= 15,
            isCurrent: currentPercent >= 10
        ))

        // Find current phase
        let currentIndex = phases.firstIndex { $0.isCurrent } ?? (phases.count - 1)

        // Estimate months to full tithe
        let percentNeeded = max(0, 10 - currentPercent)
        let monthlyIncrement = hasDebt ? 1.5 : 2.5
        let estimatedMonths = percentNeeded > 0 ? Int(ceil(percentNeeded / monthlyIncrement)) : 0

        let encouragement: String
        if currentPercent >= 10 {
            encouragement = "You're already tithing! You've honored God with your firstfruits. Now explore generous living beyond the tithe."
        } else if currentPercent >= 5 {
            encouragement = "You're halfway there! Just \((income * Decimal(string: "0.05")!).currencyFormatted) more per month to reach a full tithe. God sees your faithfulness."
        } else if currentPercent > 0 {
            encouragement = "You've already started giving — that's the hardest step! This plan will guide you to a full tithe at a pace that builds your faith."
        } else {
            encouragement = "Every great journey starts with a single step. This plan meets you where you are and walks you toward joyful generosity."
        }

        return GivingPlan(
            phases: phases,
            currentPhaseIndex: currentIndex,
            estimatedMonthsToFullTithe: estimatedMonths,
            startingPercentage: currentPercent,
            targetPercentage: 10,
            encouragement: encouragement,
            verse: "\"For I know the plans I have for you, declares the LORD, plans to prosper you and not to harm you, plans to give you hope and a future.\" — Jeremiah 29:11"
        )
    }

    // MARK: - AI-Enhanced Plan Narrative

    func buildPlanPrompt(for profile: UserProfile) -> String {
        let plan = generatePlan(for: profile)

        var prompt = """
        Generate a brief, encouraging personalized giving plan narrative for this user.
        Keep it to 3-4 short paragraphs. Be warm, practical, and Scripture-grounded.

        User's situation:
        - Monthly income: \(profile.monthlyIncome.currencyFormatted)
        - Currently giving: \(String(format: "%.1f%%", plan.startingPercentage)) of income
        - Estimated \(plan.estimatedMonthsToFullTithe) months to full tithe
        - Generosity streak: \(profile.generosityStreak) months
        - Has debt: \(profile.hasDebt ? "Yes" : "No")

        Plan phases:
        """

        for phase in plan.phases {
            prompt += "\n- \(phase.monthRange): \(phase.title) (\(String(format: "%.0f%%", phase.targetPercentage)) target)"
            prompt += phase.isComplete ? " [COMPLETED]" : (phase.isCurrent ? " [CURRENT]" : "")
        }

        prompt += """

        End with a relevant Scripture verse and a short prayer.
        Do NOT use bullet points. Write in flowing paragraphs.
        """

        return prompt
    }
}
