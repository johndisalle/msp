import Foundation
import SwiftData

@Model
final class TitheRecord {
    var date: Date
    var amount: Decimal
    var incomeSource: String
    var incomeAmount: Decimal
    var categoryRaw: String
    var recipient: String
    var note: String?
    var isRecurring: Bool
    var paymentMethodRaw: String

    var userProfile: UserProfile?

    var category: GivingCategory {
        get { GivingCategory(rawValue: categoryRaw) ?? .tithe }
        set { categoryRaw = newValue.rawValue }
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .manual }
        set { paymentMethodRaw = newValue.rawValue }
    }

    init(
        date: Date = Date(),
        amount: Decimal,
        incomeSource: String = "Primary Income",
        incomeAmount: Decimal = 0,
        category: GivingCategory = .tithe,
        recipient: String = "",
        note: String? = nil,
        isRecurring: Bool = false,
        paymentMethod: PaymentMethod = .manual
    ) {
        self.date = date
        self.amount = amount
        self.incomeSource = incomeSource
        self.incomeAmount = incomeAmount
        self.categoryRaw = category.rawValue
        self.recipient = recipient
        self.note = note
        self.isRecurring = isRecurring
        self.paymentMethodRaw = paymentMethod.rawValue
    }
}

enum GivingCategory: String, Codable, CaseIterable {
    case tithe = "Tithe"
    case offering = "Offering"
    case missions = "Missions"
    case charity = "Charity"
    case churchBuilding = "Church Building Fund"
    case benevolence = "Benevolence"
    case other = "Other"

    var icon: String {
        switch self {
        case .tithe: return "heart.fill"
        case .offering: return "hands.sparkles.fill"
        case .missions: return "globe.americas.fill"
        case .charity: return "figure.2.arms.open"
        case .churchBuilding: return "building.columns.fill"
        case .benevolence: return "hand.raised.fill"
        case .other: return "star.fill"
        }
    }

    var color: String {
        switch self {
        case .tithe: return "TitheGold"
        case .offering: return "OfferingBlue"
        case .missions: return "MissionsGreen"
        case .charity: return "CharityPurple"
        case .churchBuilding: return "BuildingOrange"
        case .benevolence: return "BenevolenceRed"
        case .other: return "OtherGray"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable {
    case manual = "Manual Entry"
    case applePay = "Apple Pay"
    case check = "Check"
    case cash = "Cash"
    case bankTransfer = "Bank Transfer"
    case online = "Online"
}
