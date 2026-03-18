import Foundation
import SwiftData
import SwiftUI

@Observable
final class DailyExperienceViewModel {
    var currentDay: JourneyDay?
    var journey: Journey?
    var journalText = ""
    var selectedMood: Mood?
    var showingJournalSheet = false
    var showingCheckInSheet = false
    var showingPrayerTimer = false
    var actionSteps: [ActionStep] = []

    let prayerTimer = PrayerTimerService()

    func loadCurrentDay(from journeys: [Journey]) {
        guard let activeJourney = journeys.first(where: { $0.isActive && !$0.isCompleted }) else {
            return
        }

        journey = activeJourney

        // Find the current day (first uncompleted and unlocked day)
        let sortedDays = activeJourney.days.sorted { $0.dayNumber < $1.dayNumber }
        currentDay = sortedDays.first(where: { !$0.isCompleted && $0.isUnlocked })
            ?? sortedDays.first(where: { !$0.isCompleted })

        if let day = currentDay {
            actionSteps = day.actionSteps

            // Start Live Activity for today's devotional
            LiveActivityService.shared.startDevotionalActivity(
                journeyTitle: activeJourney.title,
                dayNumber: day.dayNumber,
                totalDays: activeJourney.totalDays,
                verseSnippet: String(day.scriptureText.prefix(80)),
                verseReference: day.scriptureReference,
                focusArea: day.focusArea.rawValue
            )
        }

        // Request HealthKit authorization on first load
        Task {
            _ = await HealthKitService.shared.requestAuthorization()
        }
    }

    func toggleActionStep(at index: Int) {
        guard index < actionSteps.count else { return }
        actionSteps[index].isCompleted.toggle()
        currentDay?.actionSteps = actionSteps
    }

    func completeDay(context: ModelContext) {
        guard let day = currentDay, let journey = journey else { return }

        day.isCompleted = true
        day.date = Date()
        day.actionSteps = actionSteps

        // Save journal entry if there's text
        if !journalText.isEmpty {
            let entry = JournalEntry(text: journalText, mood: selectedMood)
            entry.journeyDay = day
            context.insert(entry)
        }

        // Unlock next day
        let nextDayNumber = day.dayNumber + 1
        if let nextDay = journey.days.first(where: { $0.dayNumber == nextDayNumber }) {
            nextDay.isUnlocked = true
        }

        // Update journey progress
        journey.currentDay = day.dayNumber

        // Check if journey is complete
        if day.dayNumber >= journey.totalDays {
            journey.isCompleted = true
            journey.isActive = false
        }

        // Adapt upcoming content based on check-in patterns
        let analysis = AdaptiveJourneyService.shared.analyzeRecentWeek(journey: journey)
        AdaptiveJourneyService.shared.adaptUpcomingContent(journey: journey, analysis: analysis)

        try? context.save()

        // Schedule next day's notifications
        if let profile = journey.user, let nextDay = journey.days.first(where: { $0.dayNumber == nextDayNumber }) {
            NotificationService.shared.scheduleMorningReminder(
                at: profile.notificationMorningTime,
                dayNumber: nextDayNumber,
                verseSnippet: String(nextDay.scriptureText.prefix(60))
            )
            NotificationService.shared.scheduleEveningCheckIn(
                at: profile.notificationEveningTime,
                dayNumber: nextDayNumber
            )
        }

        // Reset for next day
        journalText = ""
        selectedMood = nil
        loadCurrentDay(from: journey.user?.journeys ?? [])
    }

    func submitCheckIn(rating: CheckInRating, note: String?, context: ModelContext) {
        guard let day = currentDay else { return }

        let completedSteps = actionSteps.filter { $0.isCompleted }.count
        let checkIn = DailyCheckIn(
            rating: rating,
            note: note,
            prayerMinutes: prayerTimer.elapsedMinutes,
            completedActionSteps: completedSteps,
            totalActionSteps: actionSteps.count
        )
        checkIn.journeyDay = day
        context.insert(checkIn)
        try? context.save()

        showingCheckInSheet = false
    }

    func savePrayerSession(context: ModelContext) {
        guard prayerTimer.elapsedSeconds > 0 else { return }

        let session = PrayerSession(
            startTime: prayerTimer.sessionStartDate ?? Date(),
            duration: prayerTimer.elapsedSeconds,
            type: .devotional
        )
        context.insert(session)
        try? context.save()

        // Save to HealthKit as Mindfulness session
        if let startDate = prayerTimer.sessionStartDate {
            Task {
                try? await HealthKitService.shared.saveMindfulnessSession(
                    startDate: startDate,
                    duration: prayerTimer.elapsedSeconds
                )
            }
        }

        prayerTimer.reset()
        showingPrayerTimer = false
    }
}
