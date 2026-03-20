import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var createdAt: Date
    var spiritualMaturity: SpiritualMaturity
    var preferredTranslation: BibleTranslation
    var isPremium: Bool
    var premiumExpiresAt: Date?
    var notificationMorningTime: Date
    var notificationEveningTime: Date
    var notificationsEnabled: Bool

    @Relationship(deleteRule: .cascade, inverse: \Journey.user)
    var journeys: [Journey]

    @Relationship(deleteRule: .cascade, inverse: \QuizResponse.user)
    var quizResponses: [QuizResponse]

    @Relationship(deleteRule: .cascade, inverse: \AccountabilityPartner.user)
    var accountabilityPartners: [AccountabilityPartner]

    init(
        name: String = "",
        spiritualMaturity: SpiritualMaturity = .exploring,
        preferredTranslation: BibleTranslation = .niv
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.spiritualMaturity = spiritualMaturity
        self.preferredTranslation = preferredTranslation
        self.isPremium = false
        self.premiumExpiresAt = nil
        self.notificationsEnabled = true
        self.journeys = []
        self.quizResponses = []
        self.accountabilityPartners = []

        // Default morning 7:00 AM, evening 8:00 PM
        var morningComponents = DateComponents()
        morningComponents.hour = 7
        morningComponents.minute = 0
        self.notificationMorningTime = Calendar.current.date(from: morningComponents) ?? Date()

        var eveningComponents = DateComponents()
        eveningComponents.hour = 20
        eveningComponents.minute = 0
        self.notificationEveningTime = Calendar.current.date(from: eveningComponents) ?? Date()
    }
}

enum SpiritualMaturity: String, Codable, CaseIterable {
    case exploring = "Exploring Faith"
    case newBeliever = "New Believer"
    case growing = "Growing in Faith"
    case mature = "Mature Believer"
    case leader = "Spiritual Leader"
}

enum BibleTranslation: String, Codable, CaseIterable {
    case niv = "NIV"
    case esv = "ESV"
    case kjv = "KJV"
    case nlt = "NLT"
    case nasb = "NASB"
    case amp = "AMP"

    var fullName: String {
        switch self {
        case .niv: return "New International Version"
        case .esv: return "English Standard Version"
        case .kjv: return "King James Version"
        case .nlt: return "New Living Translation"
        case .nasb: return "New American Standard Bible"
        case .amp: return "Amplified Bible"
        }
    }
}
