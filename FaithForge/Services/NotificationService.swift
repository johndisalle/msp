// NotificationService.swift
// FaithForge
//
// Manages local notifications: daily quest reminders, streak-at-risk alerts,
// challenge milestones, and friend activity nudges.

import Foundation
import UserNotifications
import Observation

@Observable
final class NotificationService {
    static let shared = NotificationService()

    var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    /// Request notification permission. Call during onboarding or first launch.
    func requestAuthorization() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
        } catch {
            print("[Notifications] Authorization failed: \(error.localizedDescription)")
        }
    }

    /// Check current authorization status.
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Daily Quest Reminder

    /// Schedule a daily reminder at the user's preferred time.
    /// Default: 8:00 AM local time.
    func scheduleDailyQuestReminder(hour: Int = 8, minute: Int = 0) {
        let content = UNMutableNotificationContent()
        content.title = "Your quests await!"
        content.body = dailyReminderBody()
        content.sound = .default
        content.categoryIdentifier = "DAILY_QUEST"
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily-quest-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error {
                print("[Notifications] Failed to schedule daily reminder: \(error)")
            }
        }
    }

    // MARK: - Streak-at-Risk Alert

    /// Schedule an evening alert if the user hasn't completed any quests today.
    /// Fires at 8:00 PM if no quest was completed.
    func scheduleStreakAtRiskAlert(currentStreak: Int) {
        guard currentStreak > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your \(currentStreak)-day streak is at risk!"
        content.body = "Complete at least one quest before midnight to keep your streak alive."
        content.sound = .default
        content.categoryIdentifier = "STREAK_RISK"
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-at-risk-\(currentStreak)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    /// Cancel streak alert (called when a quest is completed today).
    func cancelStreakAtRiskAlert() {
        center.removePendingNotificationRequests(withIdentifiers: ["streak-at-risk"])
        // Also remove any with streak count suffix
        center.getPendingNotificationRequests { requests in
            let streakIDs = requests
                .filter { $0.identifier.hasPrefix("streak-at-risk") }
                .map(\.identifier)
            self.center.removePendingNotificationRequests(withIdentifiers: streakIDs)
        }
    }

    // MARK: - Challenge Milestone

    /// Notify when a community challenge hits a milestone (50%, 75%, 100%).
    func scheduleChallengeProgressNotification(
        challengeTitle: String,
        milestonePercent: Int
    ) {
        let content = UNMutableNotificationContent()

        if milestonePercent >= 100 {
            content.title = "Challenge Complete!"
            content.body = "\"\(challengeTitle)\" goal reached! Claim your bonus XP."
        } else {
            content.title = "Challenge Update"
            content.body = "\"\(challengeTitle)\" is \(milestonePercent)% complete. Keep going!"
        }

        content.sound = .default
        content.categoryIdentifier = "CHALLENGE"

        // Fire immediately (1 second delay)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "challenge-\(challengeTitle)-\(milestonePercent)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Friend Activity Nudge

    /// Notify when a friend surpasses the user on the leaderboard.
    func scheduleFriendActivityNudge(friendName: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(friendName) just passed you!"
        content.body = "Complete a quest to reclaim your spot on the leaderboard."
        content.sound = .default
        content.categoryIdentifier = "FRIEND_ACTIVITY"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "friend-nudge-\(friendName)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Weekly Summary

    /// Schedule a weekly summary notification (Sunday at 6:00 PM).
    func scheduleWeeklySummary(weeklyXP: Int, questsCompleted: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Your Week in Review"
        content.body = "You earned \(weeklyXP) XP and completed \(questsCompleted) quests this week. Keep forging!"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly-summary",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Manage All

    /// Remove all pending FaithForge notifications.
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Re-schedule standard recurring notifications after settings change.
    func refreshScheduledNotifications(currentStreak: Int, reminderHour: Int = 8) {
        cancelAllNotifications()
        scheduleDailyQuestReminder(hour: reminderHour)
        scheduleStreakAtRiskAlert(currentStreak: currentStreak)
        scheduleWeeklySummary(weeklyXP: 0, questsCompleted: 0) // Updated on actual data later
    }

    // MARK: - Helpers

    private func dailyReminderBody() -> String {
        let bodies = [
            "Start your day with a quest and grow closer to God.",
            "New quests are ready. Let's forge some faith!",
            "Your Faith Rings are waiting to be filled today.",
            "A new day, a new chance to build holy habits.",
            "Open FaithForge and take your next step of faith.",
        ]
        return bodies.randomElement() ?? bodies[0]
    }

    // MARK: - Notification Categories (for actionable notifications)

    /// Register notification categories with actions. Call at app launch.
    func registerCategories() {
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_QUEST",
            title: "Open Quests",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Later",
            options: [.destructive]
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_QUEST",
            actions: [completeAction, dismissAction],
            intentIdentifiers: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_RISK",
            actions: [completeAction, dismissAction],
            intentIdentifiers: []
        )

        let challengeCategory = UNNotificationCategory(
            identifier: "CHALLENGE",
            actions: [completeAction],
            intentIdentifiers: []
        )

        let friendCategory = UNNotificationCategory(
            identifier: "FRIEND_ACTIVITY",
            actions: [completeAction],
            intentIdentifiers: []
        )

        let weeklyCategory = UNNotificationCategory(
            identifier: "WEEKLY_SUMMARY",
            actions: [completeAction],
            intentIdentifiers: []
        )

        center.setNotificationCategories([
            dailyCategory, streakCategory, challengeCategory,
            friendCategory, weeklyCategory,
        ])
    }
}
