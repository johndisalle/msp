import Foundation

struct GenerosityScore {
    var totalGivenThisMonth: Double
    var monthlyIncome: Double
    var currentStreak: Int // consecutive months meeting tithe goal
    var totalGivenThisYear: Double
    var annualIncome: Double

    var monthlyPercentage: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (totalGivenThisMonth / monthlyIncome) * 100
    }

    var annualPercentage: Double {
        guard annualIncome > 0 else { return 0 }
        return (totalGivenThisYear / annualIncome) * 100
    }

    var titheGoalMet: Bool {
        monthlyPercentage >= 10.0
    }

    var level: GenerosityLevel {
        switch monthlyPercentage {
        case 0..<1: return .starting
        case 1..<5: return .growing
        case 5..<10: return .faithful
        case 10..<15: return .tither
        case 15...: return .generous
        default: return .starting
        }
    }

    var remainingToTithe: Double {
        let titheTarget = monthlyIncome * 0.10
        return max(0, titheTarget - totalGivenThisMonth)
    }

    var monthlyTitheTarget: Double {
        monthlyIncome * 0.10
    }

    var progressToTithe: Double {
        guard monthlyTitheTarget > 0 else { return 0 }
        return min(1.0, totalGivenThisMonth / monthlyTitheTarget)
    }
}

enum GenerosityLevel: String, CaseIterable {
    case starting = "Seed Planter"
    case growing = "Growing Giver"
    case faithful = "Faithful Steward"
    case tither = "Joyful Tither"
    case generous = "Generous Heart"

    var description: String {
        switch self {
        case .starting: return "Every journey begins with a single step of faith"
        case .growing: return "Your generosity is growing — keep pressing in!"
        case .faithful: return "You're stewarding faithfully — almost at the tithe!"
        case .tither: return "You've honored God with your firstfruits!"
        case .generous: return "Your overflow is a blessing to many!"
        }
    }

    var verse: String {
        switch self {
        case .starting: return "\"Whoever sows sparingly will also reap sparingly.\" — 2 Corinthians 9:6"
        case .growing: return "\"Let us not become weary in doing good.\" — Galatians 6:9"
        case .faithful: return "\"Well done, good and faithful servant!\" — Matthew 25:21"
        case .tither: return "\"Test me in this... if I will not open the floodgates of heaven.\" — Malachi 3:10"
        case .generous: return "\"God loves a cheerful giver.\" — 2 Corinthians 9:7"
        }
    }

    var icon: String {
        switch self {
        case .starting: return "leaf.fill"
        case .growing: return "leaf.arrow.triangle.circlepath"
        case .faithful: return "star.fill"
        case .tither: return "heart.circle.fill"
        case .generous: return "crown.fill"
        }
    }
}
