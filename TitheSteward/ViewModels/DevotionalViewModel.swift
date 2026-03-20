import Foundation
import SwiftData

@MainActor
class DevotionalViewModel: ObservableObject {
    @Published var showingPrayerSheet = false
    @Published var personalNote: String = ""
    @Published var didPray = false

    private var devotionalService: DevotionalService?
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.devotionalService = DevotionalService(modelContext: modelContext)
    }

    var userProfile: UserProfile? {
        guard let modelContext = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first
    }

    var todaysDevotional: Devotional? {
        devotionalService?.todaysDevotional
    }

    var isCompletedToday: Bool {
        guard let profile = userProfile, let service = devotionalService else { return false }
        return service.isCompletedToday(profile: profile)
    }

    var devotionalStreak: Int {
        guard let profile = userProfile, let service = devotionalService else { return 0 }
        return service.devotionalStreak(profile: profile)
    }

    var streakText: String {
        let streak = devotionalStreak
        if streak == 0 { return "Start your streak today!" }
        return "\(streak) day\(streak == 1 ? "" : "s") in a row"
    }

    var allDevotionals: [Devotional] {
        devotionalService?.allDevotionals ?? DevotionalContentLibrary.devotionals
    }

    func markComplete() {
        guard let devotional = todaysDevotional,
              let profile = userProfile,
              let service = devotionalService else { return }
        service.markComplete(
            devotionalDay: devotional.dayOfCycle,
            didPray: didPray,
            note: personalNote.isEmpty ? nil : personalNote,
            profile: profile
        )
        showingPrayerSheet = false
        personalNote = ""
        didPray = false
        objectWillChange.send()
    }
}
