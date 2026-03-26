import Foundation
import SwiftData

@Model
final class JourneyDay {
    var id: UUID = UUID()
    var dayNumber: Int = 0
    var date: Date?
    var isCompleted: Bool = false
    var isUnlocked: Bool = false
    var hasBeenAdapted: Bool = false

    // Content
    var scriptureReference: String = ""
    var scriptureText: String = ""
    var devotionalTitle: String = ""
    var devotionalText: String = ""
    var devotionalAudioURL: String?

    // Prayer
    var prayerText: String = ""
    var hasPrayed: Bool = false

    // Action steps
    var actionSteps: [ActionStep] = []
    var reflectionPrompt: String = ""

    // Focus
    var focusArea: DiscipleshipArea = .prayer
    var theme: JourneyTheme = .knowingGod

    var journey: Journey?

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.journeyDay)
    var journalEntries: [JournalEntry]

    @Relationship(deleteRule: .cascade, inverse: \DailyCheckIn.journeyDay)
    var checkIns: [DailyCheckIn]

    init(
        dayNumber: Int,
        scriptureReference: String,
        scriptureText: String,
        devotionalTitle: String,
        devotionalText: String,
        prayerText: String = "",
        reflectionPrompt: String,
        focusArea: DiscipleshipArea,
        theme: JourneyTheme,
        actionSteps: [ActionStep] = []
    ) {
        self.id = UUID()
        self.dayNumber = dayNumber
        self.date = nil
        self.isCompleted = false
        self.isUnlocked = dayNumber == 1
        self.hasBeenAdapted = false
        self.scriptureReference = scriptureReference
        self.scriptureText = scriptureText
        self.devotionalTitle = devotionalTitle
        self.devotionalText = devotionalText
        self.devotionalAudioURL = nil
        self.prayerText = prayerText
        self.hasPrayed = false
        self.actionSteps = actionSteps
        self.reflectionPrompt = reflectionPrompt
        self.focusArea = focusArea
        self.theme = theme
        self.journalEntries = []
        self.checkIns = []
    }
}

struct ActionStep: Codable, Identifiable, Hashable {
    var id: UUID
    var text: String
    var isCompleted: Bool

    init(text: String, isCompleted: Bool = false) {
        self.id = UUID()
        self.text = text
        self.isCompleted = isCompleted
    }
}
