import Foundation
import SwiftData

@Model
final class GenerosityBadge {
    var badgeTypeRaw: String
    var earnedDate: Date
    var isNew: Bool

    var userProfile: UserProfile?

    var badgeType: BadgeType {
        get { BadgeType(rawValue: badgeTypeRaw) ?? .firstGift }
        set { badgeTypeRaw = newValue.rawValue }
    }

    init(badgeType: BadgeType, earnedDate: Date = Date(), isNew: Bool = true) {
        self.badgeTypeRaw = badgeType.rawValue
        self.earnedDate = earnedDate
        self.isNew = isNew
    }
}

enum BadgeType: String, Codable, CaseIterable {
    // Milestones
    case firstGift = "First Gift"
    case firstTithe = "First Full Tithe"
    case consistentMonth = "Consistent Month"
    case quarterStreak = "Quarter Streak"
    case yearStreak = "Year Streak"

    // Giving Levels
    case seedPlanter = "Seed Planter"
    case growingGiver = "Growing Giver"
    case faithfulSteward = "Faithful Steward"
    case joyfulTither = "Joyful Tither"
    case generousHeart = "Generous Heart"

    // Special
    case debtFreedom = "Debt Freedom"
    case firstRecurring = "First Recurring Gift"
    case multiMinistry = "Multi-Ministry Giver"
    case devotionalStreak7 = "7-Day Devotional Streak"
    case devotionalStreak30 = "30-Day Devotional Streak"
    case thousandClub = "$1,000 Club"
    case fiveThousandClub = "$5,000 Club"
    case tenThousandClub = "$10,000 Club"

    var icon: String {
        switch self {
        case .firstGift: return "gift.fill"
        case .firstTithe: return "heart.circle.fill"
        case .consistentMonth: return "calendar.badge.checkmark"
        case .quarterStreak: return "flame.fill"
        case .yearStreak: return "flame.circle.fill"
        case .seedPlanter: return "leaf.fill"
        case .growingGiver: return "leaf.arrow.triangle.circlepath"
        case .faithfulSteward: return "star.fill"
        case .joyfulTither: return "heart.circle.fill"
        case .generousHeart: return "crown.fill"
        case .debtFreedom: return "lock.open.fill"
        case .firstRecurring: return "arrow.triangle.2.circlepath"
        case .multiMinistry: return "person.3.fill"
        case .devotionalStreak7: return "book.fill"
        case .devotionalStreak30: return "book.closed.fill"
        case .thousandClub: return "banknote.fill"
        case .fiveThousandClub: return "banknote.fill"
        case .tenThousandClub: return "banknote.fill"
        }
    }

    var color: String {
        switch self {
        case .firstGift, .firstRecurring: return "AccentGold"
        case .firstTithe, .joyfulTither: return "TitheGold"
        case .consistentMonth, .quarterStreak: return "MissionsGreen"
        case .yearStreak: return "BuildingOrange"
        case .seedPlanter, .growingGiver: return "MissionsGreen"
        case .faithfulSteward: return "OfferingBlue"
        case .generousHeart: return "CharityPurple"
        case .debtFreedom: return "MissionsGreen"
        case .multiMinistry: return "OfferingBlue"
        case .devotionalStreak7, .devotionalStreak30: return "BuildingOrange"
        case .thousandClub: return "AccentGold"
        case .fiveThousandClub: return "CharityPurple"
        case .tenThousandClub: return "BenevolenceRed"
        }
    }

    var description: String {
        switch self {
        case .firstGift: return "You gave your first gift!"
        case .firstTithe: return "You gave a full 10% tithe this month"
        case .consistentMonth: return "You tithed consistently for a full month"
        case .quarterStreak: return "3 months of faithful giving"
        case .yearStreak: return "A full year of generous stewardship"
        case .seedPlanter: return "You've planted your first seeds of generosity"
        case .growingGiver: return "Your giving is growing — keep going!"
        case .faithfulSteward: return "Faithful in much, faithful in all"
        case .joyfulTither: return "Honoring God with your firstfruits"
        case .generousHeart: return "Overflowing with generosity beyond the tithe"
        case .debtFreedom: return "You've broken free from all debt!"
        case .firstRecurring: return "You set up your first recurring gift"
        case .multiMinistry: return "Giving to 3+ ministries or causes"
        case .devotionalStreak7: return "7 days of stewardship devotionals"
        case .devotionalStreak30: return "30 days of stewardship devotionals"
        case .thousandClub: return "You've given over $1,000 total"
        case .fiveThousandClub: return "You've given over $5,000 total"
        case .tenThousandClub: return "You've given over $10,000 total"
        }
    }

    var verse: String {
        switch self {
        case .firstGift: return "\"Every good gift is from above.\" — James 1:17"
        case .firstTithe: return "\"Bring the whole tithe into the storehouse.\" — Malachi 3:10"
        case .consistentMonth: return "\"Let us not become weary in doing good.\" — Galatians 6:9"
        case .quarterStreak: return "\"He who is faithful in little is faithful in much.\" — Luke 16:10"
        case .yearStreak: return "\"His mercies are new every morning.\" — Lamentations 3:23"
        case .seedPlanter: return "\"Whoever sows sparingly will also reap sparingly.\" — 2 Corinthians 9:6"
        case .growingGiver: return "\"The seed on good soil yielded a hundred fold.\" — Luke 8:8"
        case .faithfulSteward: return "\"Well done, good and faithful servant!\" — Matthew 25:21"
        case .joyfulTither: return "\"Test me in this... if I will not open the floodgates of heaven.\" — Malachi 3:10"
        case .generousHeart: return "\"God loves a cheerful giver.\" — 2 Corinthians 9:7"
        case .debtFreedom: return "\"The borrower is slave to the lender.\" — Proverbs 22:7"
        case .firstRecurring: return "\"On the first day of every week, set aside a sum.\" — 1 Corinthians 16:2"
        case .multiMinistry: return "\"The harvest is plentiful but the workers are few.\" — Matthew 9:37"
        case .devotionalStreak7: return "\"Blessed is the one who reads... this prophecy.\" — Revelation 1:3"
        case .devotionalStreak30: return "\"Your word is a lamp for my feet.\" — Psalm 119:105"
        case .thousandClub: return "\"Where your treasure is, there your heart will be.\" — Matthew 6:21"
        case .fiveThousandClub: return "\"Give, and it will be given to you.\" — Luke 6:38"
        case .tenThousandClub: return "\"You will be enriched in every way so that you can be generous.\" — 2 Corinthians 9:11"
        }
    }
}
