import Foundation

class GivingViewModel: ObservableObject {
    @Published var givingService = GivingService()
    @Published var showingAddRecipient = false
    @Published var showingQuickGive = false
    @Published var selectedRecipient: GivingRecipient?

    // Add recipient form
    @Published var newRecipientName: String = ""
    @Published var newRecipientType: RecipientType = .church
    @Published var newRecipientWebsite: String = ""

    // Quick give form
    @Published var quickGiveAmount: String = ""
    @Published var quickGiveCategory: GivingCategory = .tithe

    var recipients: [GivingRecipient] {
        givingService.recipients.sorted { $0.isFavorite && !$1.isFavorite }
    }

    var favoriteRecipients: [GivingRecipient] {
        givingService.favoriteRecipients()
    }

    var recurringGifts: [RecurringGift] {
        givingService.recurringGifts
    }

    var monthlyRecurringTotal: Double {
        givingService.monthlyRecurringTotal()
    }

    var isApplePayAvailable: Bool {
        GivingService.isApplePayAvailable
    }

    func addRecipient() {
        guard !newRecipientName.isEmpty else { return }

        let recipient = GivingRecipient(
            name: newRecipientName,
            type: newRecipientType,
            website: newRecipientWebsite.isEmpty ? nil : newRecipientWebsite
        )

        givingService.addRecipient(recipient)
        clearRecipientForm()
    }

    func toggleFavorite(_ recipient: GivingRecipient) {
        var updated = recipient
        updated.isFavorite.toggle()
        givingService.updateRecipient(updated)
    }

    func deleteRecipient(id: UUID) {
        givingService.deleteRecipient(id: id)
    }

    func toggleRecurring(id: UUID) {
        givingService.toggleRecurringGift(id: id)
    }

    func deleteRecurring(id: UUID) {
        givingService.deleteRecurringGift(id: id)
    }

    private func clearRecipientForm() {
        newRecipientName = ""
        newRecipientType = .church
        newRecipientWebsite = ""
        showingAddRecipient = false
    }

    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}
