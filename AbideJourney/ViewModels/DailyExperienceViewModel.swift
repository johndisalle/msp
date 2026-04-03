import Foundation
import SwiftData
import SwiftUI

@Observable
final class DailyExperienceViewModel {
    var currentDay: JourneyDay?
    var journey: Journey?
    var journalText = ""
    var selectedMood: Mood?
    var isVoiceJournalEntry = false
    var showingJournalSheet = false
    var showingCheckInSheet = false
    var journeyJustCompleted = false
    var milestoneDay: Int?
    var actionSteps: [ActionStep] = []
    var saveError: String?

    var dailyLimitReached = false
    var showConfetti = false

    let audioPlayer = AudioPlayerService.shared

    /// Free users: 1 day per calendar day. Premium: 3 days per calendar day.
    private func dailyCompletionLimit(isPremium: Bool) -> Int {
        isPremium ? 3 : 1
    }

    private func completionsToday(in journey: Journey) -> Int {
        let calendar = Calendar.current
        return (journey.days ?? []).filter { day in
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
        let sortedDays = (activeJourney.days ?? []).sorted { $0.dayNumber < $1.dayNumber }
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

            // Sync current day to Apple Watch
            let streakInfo = StreakService.shared.calculateStreak(for: activeJourney)
            WatchSyncService.shared.sync(
                dayNumber: day.dayNumber,
                totalDays: activeJourney.totalDays,
                currentDay: activeJourney.currentDay,
                focusArea: day.focusArea.rawValue,
                scriptureReference: day.scriptureReference,
                scriptureText: day.scriptureText,
                devotionalTitle: day.devotionalTitle,
                devotionalText: day.devotionalText,
                reflectionPrompt: day.reflectionPrompt,
                journeyTitle: activeJourney.title,
                progress: activeJourney.progress,
                currentStreak: streakInfo.currentStreak,
                longestStreak: streakInfo.longestStreak
            )
        }

    }

    func toggleActionStep(at index: Int, context: ModelContext) {
        guard 0..<actionSteps.count ~= index else { return }
        actionSteps[index].isCompleted.toggle()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        currentDay?.actionSteps = actionSteps
        try? context.save()
    }

    func completeDay(rating: CheckInRating, isPremium: Bool, context: ModelContext) {
        guard let day = currentDay, let journey = journey else { return }

        day.isCompleted = true
        day.date = Date()
        day.actionSteps = actionSteps

        // Save journal entry if there's text
        if !journalText.isEmpty {
            let entry = JournalEntry(text: journalText, mood: selectedMood, isVoiceEntry: isVoiceJournalEntry)
            entry.journeyDay = day
            context.insert(entry)
        }

        // Unlock next day
        let nextDayNumber = day.dayNumber + 1
        if let nextDay = (journey.days ?? []).first(where: { $0.dayNumber == nextDayNumber }) {
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

        // Haptic feedback for completion
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showConfetti = true

        // Check for milestone celebration
        if MilestoneCelebrationView.milestoneDays.contains(day.dayNumber) {
            milestoneDay = day.dayNumber
        }

        // Adapt upcoming content based on rolling weekly sentiment analysis.
        // The service handles all cases: grace for struggling, encouragement
        // for needs-grace, bonus challenges for thriving, and no-op for steady.
        let analysis = AdaptiveJourneyService.shared.analyzeRecentWeek(journey: journey)
        AdaptiveJourneyService.shared.adaptUpcomingContent(journey: journey, analysis: analysis)

        do {
            try context.save()
        } catch {
            saveError = "Failed to save your progress. Please try again."
        }

        // Schedule next day's notifications
        if let profile = journey.user, let nextDay = (journey.days ?? []).first(where: { $0.dayNumber == nextDayNumber }) {
            NotificationService.shared.scheduleMorningReminder(
                at: profile.notificationMorningTime,
                dayNumber: nextDayNumber,
                verseSnippet: String(nextDay.scriptureText.prefix(100))
            )
            NotificationService.shared.scheduleEveningCheckIn(
                at: profile.notificationEveningTime,
                dayNumber: nextDayNumber
            )
        }

        // Reset for next day
        journalText = ""
        selectedMood = nil
        isVoiceJournalEntry = false
        loadCurrentDay(from: [journey])
        checkDailyLimit(isPremium: isPremium)
    }

    func submitCheckIn(rating: CheckInRating, note: String?, context: ModelContext) {
        guard let day = currentDay else { return }

        let completedSteps = actionSteps.filter { $0.isCompleted }.count
        let checkIn = DailyCheckIn(
            rating: rating,
            note: note,
            prayerMinutes: 0,
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
        Analytics.checkInSubmitted(rating: rating.rawValue)

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

    func toggleBookmark(context: ModelContext) {
        guard let day = currentDay else { return }
        day.isBookmarked.toggle()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        try? context.save()
    }

    func markPrayed(context: ModelContext) {
        guard let day = currentDay else { return }
        day.hasPrayed = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Analytics.prayerCompleted()
        do {
            try context.save()
        } catch {
            saveError = "Failed to save your prayer. Please try again."
        }
    }
}
