import Foundation

struct TitheRecord: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Double
    var incomeSource: String
    var incomeAmount: Double
    var category: GivingCategory
    var recipient: String
    var note: String?
    var isRecurring: Bool
    var paymentMethod: PaymentMethod

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        incomeSource: String = "Primary Income",
        incomeAmount: Double = 0,
        category: GivingCategory = .tithe,
        recipient: String = "",
        note: String? = nil,
        isRecurring: Bool = false,
        paymentMethod: PaymentMethod = .manual
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.incomeSource = incomeSource
        self.incomeAmount = incomeAmount
        self.category = category
        self.recipient = recipient
        self.note = note
        self.isRecurring = isRecurring
        self.paymentMethod = paymentMethod
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
