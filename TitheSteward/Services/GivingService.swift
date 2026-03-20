import Foundation
import PassKit

class GivingService: ObservableObject {
    @Published var recipients: [GivingRecipient] = []
    @Published var recurringGifts: [RecurringGift] = []

    private let recipientsKey = "giving_recipients"
    private let recurringKey = "recurring_gifts"

    init() {
        loadData()
    }

    // MARK: - Apple Pay Support

    static var isApplePayAvailable: Bool {
        PKPaymentAuthorizationController.canMakePayments()
    }

    static var canMakeApplePayPayments: Bool {
        PKPaymentAuthorizationController.canMakePayments(usingNetworks: [.visa, .masterCard, .amex, .discover])
    }

    func createPaymentRequest(amount: Double, recipient: GivingRecipient) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant.com.tithesteward.app"
        request.supportedNetworks = [.visa, .masterCard, .amex, .discover]
        request.merchantCapabilities = .threeDSecure
        request.countryCode = "US"
        request.currencyCode = "USD"
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "Gift to \(recipient.name)", amount: NSDecimalNumber(value: amount))
        ]
        return request
    }

    // MARK: - Recipients

    func addRecipient(_ recipient: GivingRecipient) {
        recipients.append(recipient)
        saveRecipients()
    }

    func updateRecipient(_ recipient: GivingRecipient) {
        if let index = recipients.firstIndex(where: { $0.id == recipient.id }) {
            recipients[index] = recipient
            saveRecipients()
        }
    }

    func deleteRecipient(id: UUID) {
        recipients.removeAll { $0.id == id }
        recurringGifts.removeAll { $0.recipientId == id }
        saveRecipients()
        saveRecurring()
    }

    func favoriteRecipients() -> [GivingRecipient] {
        recipients.filter { $0.isFavorite }
    }

    // MARK: - Recurring Gifts

    func addRecurringGift(_ gift: RecurringGift) {
        recurringGifts.append(gift)
        saveRecurring()
    }

    func toggleRecurringGift(id: UUID) {
        if let index = recurringGifts.firstIndex(where: { $0.id == id }) {
            recurringGifts[index].isActive.toggle()
            saveRecurring()
        }
    }

    func deleteRecurringGift(id: UUID) {
        recurringGifts.removeAll { $0.id == id }
        saveRecurring()
    }

    func activeRecurringGifts() -> [RecurringGift] {
        recurringGifts.filter { $0.isActive }
    }

    func monthlyRecurringTotal() -> Double {
        activeRecurringGifts().reduce(0) { total, gift in
            switch gift.frequency {
            case .weekly: return total + (gift.amount * 4.33)
            case .biweekly: return total + (gift.amount * 2.17)
            case .monthly: return total + gift.amount
            case .quarterly: return total + (gift.amount / 3)
            case .annually: return total + (gift.amount / 12)
            }
        }
    }

    // MARK: - Persistence

    private func saveRecipients() {
        if let data = try? JSONEncoder().encode(recipients) {
            UserDefaults.standard.set(data, forKey: recipientsKey)
        }
    }

    private func saveRecurring() {
        if let data = try? JSONEncoder().encode(recurringGifts) {
            UserDefaults.standard.set(data, forKey: recurringKey)
        }
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: recipientsKey),
           let items = try? JSONDecoder().decode([GivingRecipient].self, from: data) {
            recipients = items
        }
        if let data = UserDefaults.standard.data(forKey: recurringKey),
           let items = try? JSONDecoder().decode([RecurringGift].self, from: data) {
            recurringGifts = items
        }
    }
}
