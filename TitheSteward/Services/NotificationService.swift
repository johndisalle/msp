import Foundation
import UserNotifications

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Tithe Reminders

    func scheduleTitheReminder(for days: [Int], time: DateComponents? = nil) {
        // Clear existing tithe reminders
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: days.map { "tithe_reminder_\($0)" }
        )

        let reminderTime = time ?? DateComponents(hour: 9, minute: 0)

        for day in days {
            let content = UNMutableNotificationContent()
            content.title = "Tithe Reminder"
            content.body = "Payday is here! Remember to honor God with your firstfruits. \"Honor the LORD with your wealth\" — Proverbs 3:9"
            content.sound = .default
            content.categoryIdentifier = "TITHE_REMINDER"

            var dateComponents = DateComponents()
            dateComponents.day = day
            dateComponents.hour = reminderTime.hour
            dateComponents.minute = reminderTime.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let request = UNNotificationRequest(
                identifier: "tithe_reminder_\(day)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Devotional Reminders

    func scheduleDevotionalReminder(at time: DateComponents) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["daily_devotional"]
        )

        let content = UNMutableNotificationContent()
        content.title = "Daily Stewardship Word"
        content.body = "Take a moment to reflect on God's wisdom for your finances today."
        content.sound = .default
        content.categoryIdentifier = "DEVOTIONAL"

        let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_devotional",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Streak Alerts

    func scheduleStreakReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["streak_reminder"]
        )

        let content = UNMutableNotificationContent()
        content.title = "Keep Your Generosity Streak!"
        content.body = "Don't break your giving streak! Log today's generosity and stay faithful."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 20
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak_reminder",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Clear All

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
