import Foundation

class DevotionalViewModel: ObservableObject {
    @Published var devotionalService = DevotionalService()
    @Published var showingPrayerSheet = false
    @Published var personalNote: String = ""
    @Published var didPray = false

    var todaysDevotional: Devotional? {
        devotionalService.todaysDevotional
    }

    var isCompletedToday: Bool {
        devotionalService.isCompletedToday()
    }

    var devotionalStreak: Int {
        devotionalService.devotionalStreak()
    }

    var streakText: String {
        let streak = devotionalStreak
        if streak == 0 { return "Start your streak today!" }
        return "\(streak) day\(streak == 1 ? "" : "s") in a row"
    }

    var allDevotionals: [Devotional] {
        devotionalService.devotionals
    }

    func markComplete() {
        guard let devotional = todaysDevotional else { return }
        devotionalService.markComplete(
            devotionalId: devotional.id,
            didPray: didPray,
            note: personalNote.isEmpty ? nil : personalNote
        )
        showingPrayerSheet = false
        personalNote = ""
        didPray = false
    }

    func recentCompletions(limit: Int = 7) -> [DevotionalCompletion] {
        Array(devotionalService.completions.sorted { $0.date > $1.date }.prefix(limit))
    }
}
