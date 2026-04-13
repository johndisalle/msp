import StoreKit
import Foundation
import UIKit

/// Strategically requests App Store reviews at peak emotional moments
/// to maximize positive ratings.
final class ReviewPromptService {
    static let shared = ReviewPromptService()
    private init() {}

    private let hasRequestedKey = "reviewPrompt_hasRequested"
    private let lastRequestDateKey = "reviewPrompt_lastRequestDate"
    private let requestCountKey = "reviewPrompt_requestCount"

    // Apple limits review prompts to 3 per 365 days
    private let maxRequestsPerYear = 3

    /// Call after a user completes their FIRST journey (Day 40 — peak accomplishment)
    func checkAfterJourneyCompletion(journeysCompleted: Int) {
        // Only prompt on first journey completion for maximum emotional impact
        guard journeysCompleted == 1 else { return }
        requestReviewIfEligible(trigger: "journey_complete")
    }

    /// Call after a prayer is marked as "answered" (peak gratitude)
    func checkAfterPrayerAnswered() {
        // Only trigger on the 2nd+ answered prayer (first might be accidental)
        let answeredCount = UserDefaults.standard.integer(forKey: "reviewPrompt_answeredPrayers")
        UserDefaults.standard.set(answeredCount + 1, forKey: "reviewPrompt_answeredPrayers")

        if answeredCount == 1 { // This is their 2nd answered prayer
            requestReviewIfEligible(trigger: "prayer_answered")
        }
    }

    /// Call after earning a milestone badge (peak achievement)
    func checkAfterBadgeEarned(badgeCount: Int) {
        // Trigger on 5th badge — enough engagement to leave a meaningful review
        if badgeCount == 5 {
            requestReviewIfEligible(trigger: "badge_milestone")
        }
    }

    /// Call after completing Day 7 (one week streak — early positive momentum)
    func checkAfterDayCompleted(dayNumber: Int) {
        if dayNumber == 7 {
            requestReviewIfEligible(trigger: "week_one")
        }
    }


    /// Call when the user hits a 7-day streak for the first time
    func checkAfterStreakMilestone(currentStreak: Int) {
        guard currentStreak == 7 else { return }
        requestReviewIfEligible(trigger: "streak_7")
    }

    /// Call after saving a journal entry — triggers on first 100+ word entry
    func checkAfterMeaningfulJournalEntry(wordCount: Int) {
        guard wordCount >= 100 else { return }
        let key = "reviewPrompt_firstLongJournalDone"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        requestReviewIfEligible(trigger: "first_long_journal")
    }

    /// Call after sharing a verse card — triggers on the 2nd share
    func checkAfterVerseCardShared() {
        let key = "reviewPrompt_verseShareCount"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
        if count + 1 == 2 {
            requestReviewIfEligible(trigger: "verse_shared")
        }
    }

    // MARK: - Core Logic

    private func requestReviewIfEligible(trigger: String) {
        let requestCount = UserDefaults.standard.integer(forKey: requestCountKey)

        // Don't exceed Apple's limit
        guard requestCount < maxRequestsPerYear else { return }

        // Don't request more than once every 60 days
        if let lastDate = UserDefaults.standard.object(forKey: lastRequestDateKey) as? Date {
            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSinceLastRequest >= 60 else { return }
        }

        // Don't trigger if user just installed (wait at least 3 days)
        let installDate = UserDefaults.standard.object(forKey: "appInstallDate") as? Date ?? Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        guard daysSinceInstall >= 3 else { return }

        // Delay slightly so it doesn't interrupt the emotional moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.requestReview()
        }

        UserDefaults.standard.set(requestCount + 1, forKey: requestCountKey)
        UserDefaults.standard.set(Date(), forKey: lastRequestDateKey)
    }

    private func requestReview() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    /// Call on first app launch to record install date
    func recordInstallDateIfNeeded() {
        if UserDefaults.standard.object(forKey: "appInstallDate") == nil {
            UserDefaults.standard.set(Date(), forKey: "appInstallDate")
        }
    }
}
