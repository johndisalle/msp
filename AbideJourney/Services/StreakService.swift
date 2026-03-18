import Foundation
import SwiftData

final class StreakService {
    static let shared = StreakService()

    private init() {}

    struct StreakInfo {
        let currentStreak: Int
        let longestStreak: Int
        let totalDaysCompleted: Int
        let completedDates: Set<DateComponents>
    }

    func calculateStreak(for journey: Journey) -> StreakInfo {
        let completedDays = journey.days
            .filter { $0.isCompleted }
            .sorted { $0.dayNumber < $1.dayNumber }

        let completedDates = Set(completedDays.compactMap { day -> DateComponents? in
            guard let date = day.date else { return nil }
            return Calendar.current.dateComponents([.year, .month, .day], from: date)
        })

        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate current streak (consecutive days ending today or yesterday)
        var checkDate = today
        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            if completedDates.contains(components) {
                currentStreak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }

        // Calculate longest streak
        let sortedDates = completedDays.compactMap { $0.date }.sorted()
        for (index, date) in sortedDates.enumerated() {
            if index == 0 {
                tempStreak = 1
            } else {
                let previousDate = sortedDates[index - 1]
                let daysDiff = calendar.dateComponents([.day], from: calendar.startOfDay(for: previousDate), to: calendar.startOfDay(for: date)).day ?? 0
                if daysDiff == 1 {
                    tempStreak += 1
                } else {
                    tempStreak = 1
                }
            }
            longestStreak = max(longestStreak, tempStreak)
        }

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDaysCompleted: completedDays.count,
            completedDates: completedDates
        )
    }

    func checkForMissedDays(journey: Journey) -> Int {
        guard let lastCompletedDay = journey.days
            .filter({ $0.isCompleted })
            .sorted(by: { $0.dayNumber > $1.dayNumber })
            .first,
            let lastDate = lastCompletedDay.date
        else { return 0 }

        let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
        return max(0, daysSince - 1)
    }
}
