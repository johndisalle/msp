import Foundation
import SwiftData

@Observable
final class ProgressViewModel {
    var streakInfo: StreakService.StreakInfo?
    var journey: Journey?
    var weeklyPrayerCount: Int = 0
    var weeklyScriptureCount: Int = 0
    var weeklyObedienceCount: Int = 0

    // Habit ring values (0.0 to 1.0)
    var prayerRingProgress: Double = 0
    var wordRingProgress: Double = 0
    var obedienceRingProgress: Double = 0
    var worshipRingProgress: Double = 0

    func loadProgress(from journeys: [Journey]) {
        guard let activeJourney = journeys.first(where: { $0.isActive }) ?? journeys.last else {
            return
        }

        journey = activeJourney
        streakInfo = StreakService.shared.calculateStreak(for: activeJourney)

        calculateHabitRings(journey: activeJourney)
        calculateWeeklyStats(journey: activeJourney)
    }

    private func calculateHabitRings(journey: Journey) {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        let weekDays = (journey.days ?? []).filter { day in
            guard let date = day.date else { return false }
            return date >= startOfWeek && day.isCompleted
        }

        // Prayer ring: based on days prayed this week (target 7)
        let prayedDays = weekDays.filter { $0.hasPrayed }.count
        prayerRingProgress = min(1.0, Double(prayedDays) / 7.0)

        // Word ring: target 7 scripture readings per week
        wordRingProgress = min(1.0, Double(weekDays.count) / 7.0)

        // Obedience ring: based on action step completion
        let completedSteps = weekDays.flatMap { $0.actionSteps }.filter { $0.isCompleted }.count
        let totalSteps = weekDays.flatMap { $0.actionSteps }.count
        obedienceRingProgress = totalSteps > 0 ? Double(completedSteps) / Double(totalSteps) : 0

        // Worship ring: check-in ratings this week
        let weekCheckIns = weekDays.flatMap { $0.checkIns ?? [] }
        let positiveCheckIns = weekCheckIns.filter { $0.rating == .great || $0.rating == .good }.count
        worshipRingProgress = weekCheckIns.isEmpty ? 0 : Double(positiveCheckIns) / Double(weekCheckIns.count)
    }

    private func calculateWeeklyStats(journey: Journey) {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()

        let weekDays = (journey.days ?? []).filter { day in
            guard let date = day.date else { return false }
            return date >= startOfWeek && day.isCompleted
        }

        weeklyPrayerCount = weekDays.filter { $0.hasPrayed }.count
        weeklyScriptureCount = weekDays.count
        weeklyObedienceCount = weekDays.flatMap { $0.actionSteps }.filter { $0.isCompleted }.count
    }
}
