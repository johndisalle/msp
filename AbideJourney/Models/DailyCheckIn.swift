import Foundation
import SwiftUI
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
    case great = "great"
    case good = "good"
    case okay = "okay"
    case tough = "tough"
    case missed = "missed"

    var label: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .okay: return "Okay"
        case .tough: return "Tough"
        case .missed: return "Missed"
        }
    }

    var icon: String {
        switch self {
        case .great: return "\u{1F525}"         // fire
        case .good: return "\u{1F44D}"          // thumbs up
        case .okay: return "\u{1F610}"          // neutral face
        case .tough: return "\u{1F613}"         // downcast face
        case .missed: return "\u{23ED}\u{FE0F}" // skip forward
        }
    }

    var sfSymbol: String {
        switch self {
        case .great: return "flame.fill"
        case .good: return "hand.thumbsup.fill"
        case .okay: return "equal.circle.fill"
        case .tough: return "cloud.rain.fill"
        case .missed: return "forward.end.fill"
        }
    }

    var color: Color {
        switch self {
        case .great: return .orange
        case .good: return .green
        case .okay: return .blue
        case .tough: return .purple
        case .missed: return .gray
        }
    }
}
