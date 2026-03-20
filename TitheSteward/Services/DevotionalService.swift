import Foundation
import SwiftData

@MainActor
class DevotionalService: ObservableObject {
    @Published var todaysDevotional: Devotional?

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadTodaysDevotional()
    }

    // MARK: - Daily Devotional

    func loadTodaysDevotional() {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let cycleDay = (dayOfYear - 1) % DevotionalContentLibrary.devotionals.count
        todaysDevotional = DevotionalContentLibrary.devotionals[cycleDay]
    }

    func markComplete(devotionalDay: Int, didPray: Bool, note: String? = nil, profile: UserProfile) {
        let completion = DevotionalCompletion(
            devotionalDay: devotionalDay,
            didPray: didPray,
            personalNote: note
        )
        completion.userProfile = profile
        profile.devotionalCompletions.append(completion)
        modelContext.insert(completion)
        try? modelContext.save()
    }

    func isCompletedToday(profile: UserProfile) -> Bool {
        let calendar = Calendar.current
        return profile.devotionalCompletions.contains { calendar.isDateInToday($0.date) }
    }

    func devotionalStreak(profile: UserProfile) -> Int {
        let calendar = Calendar.current
        let sortedCompletions = profile.devotionalCompletions.sorted { $0.date > $1.date }
        var streak = 0
        var checkDate = Date()

        while true {
            let hasCompletion = sortedCompletions.contains {
                calendar.isDate($0.date, inSameDayAs: checkDate)
            }
            if hasCompletion {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else {
                break
            }
        }
        return streak
    }

    var allDevotionals: [Devotional] {
        DevotionalContentLibrary.devotionals
    }
}
