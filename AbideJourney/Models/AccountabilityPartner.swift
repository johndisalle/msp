import Foundation
import SwiftData

@Model
final class AccountabilityPartner {
    var id: UUID = UUID()
    var name: String = ""
    var email: String = ""
    var status: PartnerStatus = PartnerStatus.invited
    var addedAt: Date = Date()
    var lastEncouragementSent: Date?

    var user: UserProfile?

    init(name: String, email: String, status: PartnerStatus = .invited) {
        self.id = UUID()
        self.name = name
        self.email = email
        self.status = status
        self.addedAt = Date()
        self.lastEncouragementSent = nil
    }
}

enum PartnerStatus: String, Codable {
    case invited = "Invited"
    case active = "Active"
    case declined = "Declined"

    var icon: String {
        switch self {
        case .invited: return "clock.fill"
        case .active: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .invited: return "orange"
        case .active: return "green"
        case .declined: return "red"
        }
    }
}
