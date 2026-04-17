import Foundation
import SwiftData

final class StreakService {
    static let shared = StreakService()

    private init() {}

    /// Number of grace days allowed per journey (forgive missed days without breaking streak)
    static let graceDaysPerJourney = 2

    /// Every N consecutive-equivalent completed days earns 1 freeze (capped at maxStoredFreezes).
    static let daysPerFreezeAccrual = 7

    /// Ceiling on earnable/stored freezes. Once at cap, user must "spend" one (via a covered gap)
    /// before another can accrue.
    static let maxStoredFreezes = 3

    struct StreakInfo {
        let currentStreak: Int
        let longestStreak: Int
        let totalDaysCompleted: Int
        let completedDates: Set<DateComponents>
        let graceDaysUsed: Int
        let graceDaysRemaining: Int
        /// Freezes left in the bank after the current walk-back settled gaps.
        let freezesAvailable: Int
        /// True if at least one freeze was consumed during this streak calculation —
        /// i.e., today's streak is still alive only because a freeze protected a gap.
        let freezeSavedStreakToday: Bool
    }

    func calculateStreak(for journey: Journey) -> StreakInfo {
        let completedDays = (journey.days ?? [])
            .filter { $0.isCompleted }
            .sorted { $0.dayNumber < $1.dayNumber }

        let completedDates = Set(completedDays.compactMap { day -> DateComponents? in
            guard let date = day.date else { return nil }
            return Calendar.current.dateComponents([.year, .month, .day], from: date)
        })

        var currentStreak = 0
        var graceDaysUsed = 0
        var longestStreak = 0
        var tempStreak = 0

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let graceDaysAllowed = Self.graceDaysPerJourney

        // Freeze budget: earned from total completions, capped at maxStoredFreezes.
        // Freezes are *derived* — not persisted — so running the calc twice is idempotent.
        let freezesEarned = min(Self.maxStoredFreezes, completedDays.count / Self.daysPerFreezeAccrual)
        var freezesUsed = 0

        // Calculate current streak. Gaps are absorbed first by grace days,
        // then by freezes, until one of: streak reaches 0, or the user runs out of both.
        var checkDate = today
        var consecutiveGaps = 0
        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if completedDates.contains(components) {
                currentStreak += 1
                consecutiveGaps = 0
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                // Gap handling: grace first (1-day forgiveness), then freezes.
                consecutiveGaps += 1
                if consecutiveGaps <= 1 && graceDaysUsed < graceDaysAllowed && currentStreak > 0 {
                    graceDaysUsed += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else if freezesUsed < freezesEarned && currentStreak > 0 {
                    // Freeze absorbs this gap.
                    freezesUsed += 1
                    consecutiveGaps = 0
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
                } else {
                    break
                }
            }
        }

        // Calculate longest streak (with same grace logic)
        let sortedDates = completedDays.compactMap { $0.date }.sorted()
        for (index, date) in sortedDates.enumerated() {
            if index == 0 {
                tempStreak = 1
            } else {
                let previousDate = sortedDates[index - 1]
                let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: previousDate), to: calendar.startOfDay(for: date)).day ?? 0
                if daysDiff <= 2 {
                    // 1 day = consecutive, 2 days = 1-day gap (grace)
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
            }
            longestStreak = max(longestStreak, tempStreak)
        }

        ReviewPromptService.shared.checkAfterStreakMilestone(currentStreak: currentStreak)

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysCompleted: completedDays.count,
            completedDates: completedDates,
            graceDaysUsed: graceDaysUsed,
            graceDaysRemaining: max(0, graceDaysAllowed - graceDaysUsed),
            freezesAvailable: max(0, freezesEarned - freezesUsed),
            freezeSavedStreakToday: freezesUsed > 0
        )
    }

    func checkForMissedDays(journey: Journey) -> Int {
        guard let lastCompletedDay = (journey.days ?? [])
            .filter({ $0.isCompleted })
            .sorted(by: { $0.dayNumber > $1.dayNumber })
            .first,
            let lastDate = lastCompletedDay.date
        else { return 0 }

        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return max(0, daysSince - 1)
    }
}
