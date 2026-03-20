import Foundation

struct GivingRecipient: Codable, Identifiable {
    let id: UUID
    var name: String
    var type: RecipientType
    var website: String?
    var applePayMerchantId: String?
    var isFavorite: Bool
    var totalGiven: Double

    init(
        id: UUID = UUID(),
        name: String,
        type: RecipientType = .church,
        website: String? = nil,
        applePayMerchantId: String? = nil,
        isFavorite: Bool = false,
        totalGiven: Double = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.website = website
        self.applePayMerchantId = applePayMerchantId
        self.isFavorite = isFavorite
        self.totalGiven = totalGiven
    }
}

enum RecipientType: String, Codable, CaseIterable {
    case church = "Church"
    case ministry = "Ministry"
    case charity = "Charity"
    case missionary = "Missionary"
    case individual = "Individual"
    case other = "Other"

    var icon: String {
        switch self {
        case .church: return "building.columns.fill"
        case .ministry: return "book.closed.fill"
        case .charity: return "heart.fill"
        case .missionary: return "globe.americas.fill"
        case .individual: return "person.fill"
        case .other: return "gift.fill"
        }
    }
}

struct RecurringGift: Codable, Identifiable {
    let id: UUID
    var recipientId: UUID
    var amount: Double
    var frequency: GiftFrequency
    var category: GivingCategory
    var nextDate: Date
    var isActive: Bool
    var note: String?

    init(
        id: UUID = UUID(),
        recipientId: UUID,
        amount: Double,
        frequency: GiftFrequency = .monthly,
        category: GivingCategory = .tithe,
        nextDate: Date = Date(),
        isActive: Bool = true,
        note: String? = nil
    ) {
        self.id = id
        self.recipientId = recipientId
        self.amount = amount
        self.frequency = frequency
        self.category = category
        self.nextDate = nextDate
        self.isActive = isActive
        self.note = note
    }
}

enum GiftFrequency: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biweekly = "Bi-Weekly"
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case annually = "Annually"
}
