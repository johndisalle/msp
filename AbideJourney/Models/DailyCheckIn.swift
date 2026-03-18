import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var id: UUID
    var date: Date
    var rating: CheckInRating
    var note: String?
    var prayerMinutes: Int
    var completedActionSteps: Int
    var totalActionSteps: Int

    var journeyDay: JourneyDay?

    init(
        rating: CheckInRating,
        note: String? = nil,
        prayerMinutes: Int = 0,
        completedActionSteps: Int = 0,
        totalActionSteps: Int = 0
    ) {
        self.id = UUID()
        self.date = Date()
        self.rating = rating
        self.note = note
        self.prayerMinutes = prayerMinutes
        self.completedActionSteps = completedActionSteps
        self.totalActionSteps = totalActionSteps
    }
}

enum CheckInRating: String, Codable, CaseIterable {
    case great = "🔥"
    case good = "👍"
    case okay = "😐"
    case tough = "😓"
    case missed = "⏭️"

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .tough: return "Tough"
        case .missed: return "Missed"
        }
    }
}
