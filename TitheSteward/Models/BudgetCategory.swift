import Foundation

struct BudgetCategory: Codable, Identifiable {
    let id: UUID
    var name: String
    var type: BudgetCategoryType
    var budgetedAmount: Double
    var icon: String
    var colorName: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        type: BudgetCategoryType,
        budgetedAmount: Double = 0,
        icon: String = "folder.fill",
        colorName: String = "AccentGold",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.budgetedAmount = budgetedAmount
        self.icon = icon
        self.colorName = colorName
        self.sortOrder = sortOrder
    }

    static var defaults: [BudgetCategory] {
        [
            BudgetCategory(name: "Tithe & Giving", type: .giving, icon: "heart.fill", colorName: "TitheGold", sortOrder: 0),
            BudgetCategory(name: "Housing", type: .necessity, icon: "house.fill", colorName: "NecessityBlue", sortOrder: 1),
            BudgetCategory(name: "Food & Groceries", type: .necessity, icon: "cart.fill", colorName: "NecessityBlue", sortOrder: 2),
            BudgetCategory(name: "Transportation", type: .necessity, icon: "car.fill", colorName: "NecessityBlue", sortOrder: 3),
            BudgetCategory(name: "Utilities", type: .necessity, icon: "bolt.fill", colorName: "NecessityBlue", sortOrder: 4),
            BudgetCategory(name: "Insurance", type: .necessity, icon: "shield.fill", colorName: "NecessityBlue", sortOrder: 5),
            BudgetCategory(name: "Debt Payments", type: .debt, icon: "creditcard.fill", colorName: "DebtRed", sortOrder: 6),
            BudgetCategory(name: "Savings & Emergency", type: .savings, icon: "banknote.fill", colorName: "SavingsGreen", sortOrder: 7),
            BudgetCategory(name: "Entertainment", type: .discretionary, icon: "theatermasks.fill", colorName: "DiscretionaryPurple", sortOrder: 8),
            BudgetCategory(name: "Personal Care", type: .discretionary, icon: "person.fill", colorName: "DiscretionaryPurple", sortOrder: 9),
        ]
    }
}

enum BudgetCategoryType: String, Codable, CaseIterable {
    case giving = "Giving"
    case necessity = "Necessities"
    case debt = "Debt"
    case savings = "Savings"
    case discretionary = "Discretionary"

    var sortPriority: Int {
        switch self {
        case .giving: return 0
        case .necessity: return 1
        case .debt: return 2
        case .savings: return 3
        case .discretionary: return 4
        }
    }

    var biblicalNote: String {
        switch self {
        case .giving: return "\"Honor the LORD with your wealth, with the firstfruits of all your crops.\" — Proverbs 3:9"
        case .necessity: return "\"But if anyone does not provide for his relatives... he has denied the faith.\" — 1 Timothy 5:8"
        case .debt: return "\"The borrower is slave to the lender.\" — Proverbs 22:7"
        case .savings: return "\"The wise store up choice food and olive oil, but fools gulp theirs down.\" — Proverbs 21:20"
        case .discretionary: return "\"For where your treasure is, there your heart will be also.\" — Matthew 6:21"
        }
    }
}

struct BudgetTransaction: Codable, Identifiable {
    let id: UUID
    var date: Date
    var amount: Double
    var categoryId: UUID
    var description: String
    var note: String?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        categoryId: UUID,
        description: String,
        note: String? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.categoryId = categoryId
        self.description = description
        self.note = note
    }
}
