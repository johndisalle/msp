import Foundation
import SwiftData

@MainActor
class GivingViewModel: ObservableObject {
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

    private var givingService: GivingService?
    private var modelContext: ModelContext?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.givingService = GivingService(modelContext: modelContext)
    }

    var userProfile: UserProfile? {
        guard let modelContext = modelContext else { return nil }
        let descriptor = FetchDescriptor<UserProfile>()
        return (try? modelContext.fetch(descriptor))?.first
    }

    var recipients: [GivingRecipient] {
        (givingService?.fetchRecipients() ?? []).sorted { $0.isFavorite && !$1.isFavorite }
    }

    var favoriteRecipients: [GivingRecipient] {
        givingService?.favoriteRecipients() ?? []
    }

    var recurringGifts: [RecurringGift] {
        givingService?.fetchRecurringGifts() ?? []
    }

    var monthlyRecurringTotal: Decimal {
        givingService?.monthlyRecurringTotal() ?? 0
    }

    var isApplePayAvailable: Bool {
        GivingService.isApplePayAvailable
    }

    func addRecipient() {
        guard !newRecipientName.isEmpty,
              let profile = userProfile,
              let service = givingService else { return }

        let recipient = GivingRecipient(
            name: newRecipientName,
            type: newRecipientType,
            website: newRecipientWebsite.isEmpty ? nil : newRecipientWebsite
        )

        service.addRecipient(recipient, to: profile)
        clearRecipientForm()
        objectWillChange.send()
    }

    func toggleFavorite(_ recipient: GivingRecipient) {
        recipient.isFavorite.toggle()
        givingService?.save()
        objectWillChange.send()
    }

    func deleteRecipient(_ recipient: GivingRecipient) {
        givingService?.deleteRecipient(recipient)
        objectWillChange.send()
    }

    func deleteRecurring(_ gift: RecurringGift) {
        givingService?.deleteRecurringGift(gift)
        objectWillChange.send()
    }

    private func clearRecipientForm() {
        newRecipientName = ""
        newRecipientType = .church
        newRecipientWebsite = ""
        showingAddRecipient = false
    }
}
