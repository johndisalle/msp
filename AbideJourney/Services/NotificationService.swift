import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Morning Devotional Reminder

    func scheduleMorningReminder(at time: Date, dayNumber: Int, verseSnippet: String) {
        let content = UNMutableNotificationContent()
        content.title = "Day \(dayNumber) — Your Verse Today"
        content.subtitle = "Good Morning ☀️"
        content.body = "\u{201C}\(verseSnippet)\u{201D}\nTap to read today's devotional."
        content.sound = .default
        content.categoryIdentifier = "MORNING_DEVOTIONAL"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "morning-\(dayNumber)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Evening Check-In

    func scheduleEveningCheckIn(at time: Date, dayNumber: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Evening Reflection 🌙"
        content.body = "How was Day \(dayNumber)? Take a moment to reflect and journal before the day ends."
        content.sound = .default
        content.categoryIdentifier = "EVENING_CHECKIN"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "evening-\(dayNumber)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Grace Reminder (after missed days)

    func scheduleGraceReminder() {
        let content = UNMutableNotificationContent()
        content.title = "We Miss You"
        content.body = "Even Peter denied Jesus three times—let's restart fresh. Your journey is waiting."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3600, repeats: false)

        let request = UNNotificationRequest(
            identifier: "grace-reminder",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    // MARK: - Cancel

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func cancelNotification(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Notification Categories

    func registerCategories() {
        let startAction = UNNotificationAction(
            identifier: "START_DEVOTIONAL",
            title: "Start Devotional",
            options: .foreground
        )

        let prayAction = UNNotificationAction(
            identifier: "START_PRAYER",
            title: "Pray Now",
            options: .foreground
        )

        let checkInGreat = UNNotificationAction(identifier: "CHECKIN_GREAT", title: "\u{1F525} Great")
        let checkInGood = UNNotificationAction(identifier: "CHECKIN_GOOD", title: "\u{1F44D} Good")
        let checkInTough = UNNotificationAction(identifier: "CHECKIN_TOUGH", title: "\u{1F613} Tough")

        let morningCategory = UNNotificationCategory(
            identifier: "MORNING_DEVOTIONAL",
            actions: [startAction, prayAction],
            intentIdentifiers: []
        )

        let eveningCategory = UNNotificationCategory(
            identifier: "EVENING_CHECKIN",
            actions: [checkInGreat, checkInGood, checkInTough],
            intentIdentifiers: []
        )

        center.setNotificationCategories([morningCategory, eveningCategory])
    }
}
