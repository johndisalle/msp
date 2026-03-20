import Foundation
import SwiftData

@Model
final class GivingRecipient {
    var name: String
    var typeRaw: String
    var website: String?
    var applePayMerchantId: String?
    var isFavorite: Bool
    var totalGiven: Decimal

    var userProfile: UserProfile?
    @Relationship(deleteRule: .cascade) var recurringGifts: [RecurringGift]

    var type: RecipientType {
        get { RecipientType(rawValue: typeRaw) ?? .church }
        set { typeRaw = newValue.rawValue }
    }

    init(
        name: String,
        type: RecipientType = .church,
        website: String? = nil,
        applePayMerchantId: String? = nil,
        isFavorite: Bool = false,
        totalGiven: Decimal = 0
    ) {
        self.name = name
        self.typeRaw = type.rawValue
        self.website = website
        self.applePayMerchantId = applePayMerchantId
        self.isFavorite = isFavorite
        self.totalGiven = totalGiven
        self.recurringGifts = []
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

@Model
final class RecurringGift {
    var amount: Decimal
    var frequencyRaw: String
    var categoryRaw: String
    var nextDate: Date
    var isActive: Bool
    var note: String?

    var recipient: GivingRecipient?

    var frequency: GiftFrequency {
        get { GiftFrequency(rawValue: frequencyRaw) ?? .monthly }
        set { frequencyRaw = newValue.rawValue }
    }

    var category: GivingCategory {
        get { GivingCategory(rawValue: categoryRaw) ?? .tithe }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        amount: Decimal,
        frequency: GiftFrequency = .monthly,
        category: GivingCategory = .tithe,
        nextDate: Date = Date(),
        isActive: Bool = true,
        note: String? = nil
    ) {
        self.amount = amount
        self.frequencyRaw = frequency.rawValue
        self.categoryRaw = category.rawValue
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
