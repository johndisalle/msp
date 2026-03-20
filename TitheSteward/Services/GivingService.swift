import Foundation
import PassKit
import SwiftData

@MainActor
class GivingService: ObservableObject {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Apple Pay Support

    static var isApplePayAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    static var canMakeApplePayPayments: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex, .discover])
    }

    func createPaymentRequest(amount: Decimal, recipient: GivingRecipient) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.tithesteward.app"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Gift to \(recipient.name)", amount: NSDecimalNumber(decimal: amount))
        ]
        return request
    }

    // MARK: - Recipients

    func fetchRecipients() -> [GivingRecipient] {
        let descriptor = FetchDescriptor<GivingRecipient>(
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addRecipient(_ recipient: GivingRecipient, to profile: UserProfile) {
        recipient.userProfile = profile
        profile.recipients.append(recipient)
        modelContext.insert(recipient)
        try? modelContext.save()
    }

    func deleteRecipient(_ recipient: GivingRecipient) {
        modelContext.delete(recipient)
        try? modelContext.save()
    }

    func favoriteRecipients() -> [GivingRecipient] {
        fetchRecipients().filter { $0.isFavorite }
    }

    // MARK: - Recurring Gifts

    func fetchRecurringGifts() -> [RecurringGift] {
        let descriptor = FetchDescriptor<RecurringGift>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addRecurringGift(_ gift: RecurringGift, to recipient: GivingRecipient) {
        gift.recipient = recipient
        recipient.recurringGifts.append(gift)
        modelContext.insert(gift)
        try? modelContext.save()
    }

    func deleteRecurringGift(_ gift: RecurringGift) {
        modelContext.delete(gift)
        try? modelContext.save()
    }

    func monthlyRecurringTotal() -> Decimal {
        fetchRecurringGifts().filter { $0.isActive }.reduce(Decimal.zero) { total, gift in
            switch gift.frequency {
            case .weekly: return total + (gift.amount * Decimal(string: "4.33")!)
            case .biweekly: return total + (gift.amount * Decimal(string: "2.17")!)
            case .monthly: return total + gift.amount
            case .quarterly: return total + (gift.amount / 3)
            case .annually: return total + (gift.amount / 12)
            }
        }
    }

    // MARK: - Auto-Processing

    func processDueRecurringGifts(for profile: UserProfile) -> [TitheRecord] {
        let now = Date()
        let gifts = fetchRecurringGifts().filter { $0.isActive && $0.nextDate <= now }
        var created: [TitheRecord] = []

        for gift in gifts {
            let record = TitheRecord(
                date: now,
                amount: gift.amount,
                category: gift.category,
                recipient: gift.recipient?.name ?? "",
                note: "Auto-created from recurring gift",
                isRecurring: true
            )
            record.userProfile = profile
            profile.titheRecords.append(record)
            modelContext.insert(record)

            // Advance next date
            let calendar = Calendar.current
            switch gift.frequency {
            case .weekly:
                gift.nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: gift.nextDate) ?? now
            case .biweekly:
                gift.nextDate = calendar.date(byAdding: .weekOfYear, value: 2, to: gift.nextDate) ?? now
            case .monthly:
                gift.nextDate = calendar.date(byAdding: .month, value: 1, to: gift.nextDate) ?? now
            case .quarterly:
                gift.nextDate = calendar.date(byAdding: .month, value: 3, to: gift.nextDate) ?? now
            case .annually:
                gift.nextDate = calendar.date(byAdding: .year, value: 1, to: gift.nextDate) ?? now
            }

            created.append(record)
        }

        if !created.isEmpty {
            try? modelContext.save()
        }
        return created
    }

    func save() {
        try? modelContext.save()
    }
}
