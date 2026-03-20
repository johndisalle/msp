import Foundation
import SwiftData

@MainActor
class BadgeService {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Badge Evaluation

    func evaluateAndAwardBadges(for profile: UserProfile) -> [GenerosityBadge] {
        let existing = Set(profile.badges.map { $0.badgeType })
        var newBadges: [GenerosityBadge] = []

        let titheService = TitheCalculatorService(modelContext: modelContext)
        let givingService = GivingService(modelContext: modelContext)
        let score = titheService.calculateGenerosityScore(for: profile)

        // First Gift
        if !existing.contains(.firstGift) && !profile.titheRecords.isEmpty {
            newBadges.append(award(.firstGift, to: profile))
        }

        // First Full Tithe
        if !existing.contains(.firstTithe) && score.titheGoalMet {
            newBadges.append(award(.firstTithe, to: profile))
        }

        // Generosity level badges
        let levelBadgeMap: [GenerosityLevel: BadgeType] = [
            .starting: .seedPlanter,
            .growing: .growingGiver,
            .faithful: .faithfulSteward,
            .tither: .joyfulTither,
            .generous: .generousHeart,
        ]
        if let badge = levelBadgeMap[score.level], !existing.contains(badge) {
            newBadges.append(award(badge, to: profile))
        }

        // Streak badges
        if !existing.contains(.consistentMonth) && profile.generosityStreak >= 1 {
            newBadges.append(award(.consistentMonth, to: profile))
        }
        if !existing.contains(.quarterStreak) && profile.generosityStreak >= 3 {
            newBadges.append(award(.quarterStreak, to: profile))
        }
        if !existing.contains(.yearStreak) && profile.generosityStreak >= 12 {
            newBadges.append(award(.yearStreak, to: profile))
        }

        // Recurring giving
        let recurringGifts = givingService.fetchRecurringGifts().filter { $0.isActive }
        if !existing.contains(.firstRecurring) && !recurringGifts.isEmpty {
            newBadges.append(award(.firstRecurring, to: profile))
        }

        // Multi-ministry (3+ distinct recipients)
        let uniqueRecipients = Set(profile.titheRecords.map { $0.recipient }).subtracting([""])
        if !existing.contains(.multiMinistry) && uniqueRecipients.count >= 3 {
            newBadges.append(award(.multiMinistry, to: profile))
        }

        // Devotional streaks
        let completions = profile.devotionalCompletions.count
        if !existing.contains(.devotionalStreak7) && completions >= 7 {
            newBadges.append(award(.devotionalStreak7, to: profile))
        }
        if !existing.contains(.devotionalStreak30) && completions >= 30 {
            newBadges.append(award(.devotionalStreak30, to: profile))
        }

        // Giving total milestones
        let totalGiven = profile.totalGivenAllTime
        if !existing.contains(.thousandClub) && totalGiven >= 1000 {
            newBadges.append(award(.thousandClub, to: profile))
        }
        if !existing.contains(.fiveThousandClub) && totalGiven >= 5000 {
            newBadges.append(award(.fiveThousandClub, to: profile))
        }
        if !existing.contains(.tenThousandClub) && totalGiven >= 10000 {
            newBadges.append(award(.tenThousandClub, to: profile))
        }

        // Debt freedom
        let debtDescriptor = FetchDescriptor<DebtItem>()
        let debts = (try? modelContext.fetch(debtDescriptor)) ?? []
        let allPaidOff = !debts.isEmpty && debts.allSatisfy { $0.currentBalance <= 0 }
        if !existing.contains(.debtFreedom) && allPaidOff {
            newBadges.append(award(.debtFreedom, to: profile))
        }

        if !newBadges.isEmpty {
            try? modelContext.save()
        }

        return newBadges
    }

    // MARK: - Helpers

    private func award(_ type: BadgeType, to profile: UserProfile) -> GenerosityBadge {
        let badge = GenerosityBadge(badgeType: type)
        badge.userProfile = profile
        profile.badges.append(badge)
        modelContext.insert(badge)
        return badge
    }

    func markBadgeSeen(_ badge: GenerosityBadge) {
        badge.isNew = false
        try? modelContext.save()
    }

    func fetchBadges(for profile: UserProfile) -> [GenerosityBadge] {
        profile.badges.sorted { $0.earnedDate > $1.earnedDate }
    }

    func newBadgeCount(for profile: UserProfile) -> Int {
        profile.badges.filter { $0.isNew }.count
    }
}
