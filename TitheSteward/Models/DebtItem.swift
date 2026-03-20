import Foundation

struct DebtItem: Codable, Identifiable {
    let id: UUID
    var name: String
    var originalBalance: Double
    var currentBalance: Double
    var interestRate: Double
    var minimumPayment: Double
    var type: DebtType
    var startDate: Date
    var note: String?

    init(
        id: UUID = UUID(),
        name: String,
        originalBalance: Double,
        currentBalance: Double,
        interestRate: Double = 0,
        minimumPayment: Double = 0,
        type: DebtType = .other,
        startDate: Date = Date(),
        note: String? = nil
    ) {
        self.id = id
        self.name = name
        self.originalBalance = originalBalance
        self.currentBalance = currentBalance
        self.interestRate = interestRate
        self.minimumPayment = minimumPayment
        self.type = type
        self.startDate = startDate
        self.note = note
    }

    var percentPaid: Double {
        guard originalBalance > 0 else { return 0 }
        return max(0, min(1, 1 - (currentBalance / originalBalance)))
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

struct DebtPayment: Codable, Identifiable {
    let id: UUID
    var debtId: UUID
    var date: Date
    var amount: Double
    var note: String?

    init(id: UUID = UUID(), debtId: UUID, date: Date = Date(), amount: Double, note: String? = nil) {
        self.id = id
        self.debtId = debtId
        self.date = date
        self.amount = amount
        self.note = note
    }
}
