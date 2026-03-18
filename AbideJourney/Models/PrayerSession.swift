import Foundation
import SwiftData

@Model
final class PrayerSession {
    var id: UUID
    var startTime: Date
    var duration: TimeInterval
    var type: PrayerType

    init(startTime: Date = Date(), duration: TimeInterval, type: PrayerType = .freeform) {
        self.id = UUID()
        self.startTime = startTime
        self.duration = duration
        self.type = type
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }
}

enum PrayerType: String, Codable, CaseIterable {
    case freeform = "Freeform"
    case guided = "Guided"
    case devotional = "Devotional"
    case intercession = "Intercession"
}
