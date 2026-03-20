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

    // MARK: - Recurring Gift Reminders

    func scheduleRecurringGiftReminder(giftId: String, recipientName: String, amount: Decimal, nextDate: Date) {
        let identifier = "recurring_gift_\(giftId)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Recurring Gift Due"
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let amountStr = formatter.string(from: amount as NSDecimalNumber) ?? "$\(amount)"
        content.body = "Your \(amountStr) gift to \(recipientName) is scheduled for today. \"Each of you should give what you have decided in your heart.\" — 2 Cor 9:7"
        content.sound = .default
        content.categoryIdentifier = "RECURRING_GIFT"

        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: nextDate)
        var triggerComponents = DateComponents()
        triggerComponents.year = components.year
        triggerComponents.month = components.month
        triggerComponents.day = components.day
        triggerComponents.hour = 8 // 8 AM reminder

        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func clearRecurringGiftReminders() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix("recurring_gift_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Clear All

    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
