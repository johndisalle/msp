import Foundation
import SwiftData
import WidgetKit

@MainActor
class RecurringGiftScheduler {
    static let shared = RecurringGiftScheduler()

    private init() {}

    /// Process all due recurring gifts and schedule upcoming notifications.
    /// Call this on app launch and when returning to foreground.
    func processAndSchedule(modelContext: ModelContext) {
        let givingService = GivingService(modelContext: modelContext)

        // Find profile
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        // Auto-create records for due gifts
        let created = givingService.processDueRecurringGifts(for: profile)

        if !created.isEmpty {
            // Update widget data with new tithe records, then refresh widgets
            let titheService = TitheCalculatorService(modelContext: modelContext)
            let devotionalService = DevotionalService(modelContext: modelContext)
            WidgetDataService.updateFromServices(
                titheService: titheService,
                devotionalService: devotionalService,
                profile: profile
            )
            WidgetCenter.shared.reloadAllTimelines()
        }

        // Schedule notifications for upcoming gifts
        let upcomingGifts = givingService.fetchRecurringGifts().filter { $0.isActive }
        for gift in upcomingGifts {
            NotificationService.shared.scheduleRecurringGiftReminder(
                giftId: gift.persistentModelID.hashValue.description,
                recipientName: gift.recipient?.name ?? "Gift",
                amount: gift.amount,
                nextDate: gift.nextDate
            )
        }
    }
}
