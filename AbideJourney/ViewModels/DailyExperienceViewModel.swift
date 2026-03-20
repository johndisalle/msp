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
    var journeyJustCompleted = false
    var actionSteps: [ActionStep] = []
    var saveError: String?

    var dailyLimitReached = false

    let prayerTimer = PrayerTimerService()
    let audioPlayer = AudioPlayerService.shared

    /// Free users: 1 day per calendar day. Premium: 3 days per calendar day.
    private func dailyCompletionLimit(isPremium: Bool) -> Int {
        isPremium ? 3 : 1
    }

    private func completionsToday(in journey: Journey) -> Int {
        let calendar = Calendar.current
        return journey.days.filter { day in
            guard day.isCompleted, let date = day.date else { return false }
            return calendar.isDateInToday(date)
        }.count
    }

    func checkDailyLimit(isPremium: Bool) {
        guard let journey else {
            dailyLimitReached = false
            return
        }
        dailyLimitReached = completionsToday(in: journey) >= dailyCompletionLimit(isPremium: isPremium)
    }

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

            // Update widget data
            WidgetDataService.shared.updateWidgetData(
                dayNumber: day.dayNumber,
                totalDays: activeJourney.totalDays,
                verseReference: day.scriptureReference,
                verseSnippet: String(day.scriptureText.prefix(120)),
                focusArea: day.focusArea.rawValue,
                progress: activeJourney.progress,
                journeyTitle: activeJourney.title
            )

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

    func completeDay(rating: CheckInRating, isPremium: Bool, context: ModelContext) {
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
            journeyJustCompleted = true
        }

        // Adapt upcoming content only when the current check-in warrants it
        // (missed or tough), not based on stale history from the rolling window
        if rating == .missed || rating == .tough {
            let analysis = AdaptiveJourneyService.shared.analyzeRecentWeek(journey: journey)
            AdaptiveJourneyService.shared.adaptUpcomingContent(journey: journey, analysis: analysis)
        }

        do {
            try context.save()
        } catch {
            saveError = "Failed to save your progress. Please try again."
        }

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
        loadCurrentDay(from: [journey])
        checkDailyLimit(isPremium: isPremium)
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
        do {
            try context.save()
        } catch {
            saveError = "Failed to save your check-in. Please try again."
        }

        showingCheckInSheet = false
    }

    func toggleAudio(for day: JourneyDay) {
        if audioPlayer.isPlaying {
            audioPlayer.togglePlayPause()
        } else if audioPlayer.currentTime > 0 && !audioPlayer.isPlaying {
            // Resume paused audio
            audioPlayer.togglePlayPause()
        } else if let urlString = day.devotionalAudioURL {
            audioPlayer.play(urlString: urlString)
        }
    }

    func savePrayerSession(context: ModelContext) {
        guard prayerTimer.elapsedSeconds > 0 else { return }

        let session = PrayerSession(
            startTime: prayerTimer.sessionStartDate ?? Date(),
            duration: prayerTimer.elapsedSeconds,
            type: .devotional
        )
        context.insert(session)
        do {
            try context.save()
        } catch {
            saveError = "Failed to save your prayer session. Please try again."
        }

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
