import Foundation
import SwiftData

@Model
final class DebtItem {
    var name: String
    var originalBalance: Decimal
    var currentBalance: Decimal
    var interestRate: Double
    var minimumPayment: Decimal
    var typeRaw: String
    var startDate: Date
    var note: String?

    var userProfile: UserProfile?
    @Relationship(deleteRule: .cascade) var payments: [DebtPayment]

    var type: DebtType {
        get { DebtType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }

    var percentPaid: Double {
        guard originalBalance > 0 else { return 0 }
        let ratio = (originalBalance - currentBalance) / originalBalance
        return max(0, min(1, NSDecimalNumber(decimal: ratio).doubleValue))
    }

    init(
        name: String,
        originalBalance: Decimal,
        currentBalance: Decimal,
        interestRate: Double = 0,
        minimumPayment: Decimal = 0,
        type: DebtType = .other,
        startDate: Date = Date(),
        note: String? = nil
    ) {
        self.name = name
        self.originalBalance = originalBalance
        self.currentBalance = currentBalance
        self.interestRate = interestRate
        self.minimumPayment = minimumPayment
        self.typeRaw = type.rawValue
        self.startDate = startDate
        self.note = note
        self.payments = []
    }
}

enum DebtType: String, Codable, CaseIterable {
    case creditCard = "Credit Card"
    case studentLoan = "Student Loan"
    case autoLoan = "Auto Loan"
    case mortgage = "Mortgage"
    case personalLoan = "Personal Loan"
    case medical = "Medical"
    case other = "Other"

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .studentLoan: return "graduationcap.fill"
        case .autoLoan: return "car.fill"
        case .mortgage: return "house.fill"
        case .personalLoan: return "person.fill"
        case .medical: return "cross.case.fill"
        case .other: return "doc.fill"
        }
    }

    var encouragementVerse: String {
        switch self {
        case .creditCard: return "\"Owe no one anything, except to love each other.\" — Romans 13:8"
        case .studentLoan: return "\"The heart of the discerning acquires knowledge.\" — Proverbs 18:15"
        case .autoLoan: return "\"Better is a little with righteousness than great revenues with injustice.\" — Proverbs 16:8"
        case .mortgage: return "\"By wisdom a house is built, and through understanding it is established.\" — Proverbs 24:3"
        case .personalLoan: return "\"The wicked borrows but does not pay back, but the righteous is generous.\" — Psalm 37:21"
        case .medical: return "\"He heals the brokenhearted and binds up their wounds.\" — Psalm 147:3"
        case .other: return "\"I can do all things through him who strengthens me.\" — Philippians 4:13"
        }
    }
}

@Model
final class DebtPayment {
    var date: Date
    var amount: Decimal
    var note: String?

    var debt: DebtItem?

    init(date: Date = Date(), amount: Decimal, note: String? = nil) {
        self.date = date
        self.amount = amount
        self.note = note
    }
}
