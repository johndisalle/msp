import Foundation
import SwiftUI

// MARK: - Prayer Request Model

struct PrayerRequest: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var text: String
    var category: PrayerCategory
    var createdAt: Date = Date()
    var isAnswered: Bool = false
    var answeredAt: Date?
    var answeredNote: String?
    var prayedCount: Int = 0
    var lastPrayedAt: Date?

    enum PrayerCategory: String, Codable, CaseIterable {
        case personal = "Personal"
        case family = "Family"
        case health = "Health"
        case work = "Work & Purpose"
        case relationships = "Relationships"
        case world = "World & Community"
        case gratitude = "Gratitude"
        case other = "Other"

        var icon: String {
            switch self {
            case .personal: return "person.fill"
            case .family: return "house.fill"
            case .health: return "heart.fill"
            case .work: return "briefcase.fill"
            case .relationships: return "person.2.fill"
            case .world: return "globe.americas.fill"
            case .gratitude: return "hands.sparkles.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .personal: return .blue
            case .family: return .orange
            case .health: return .red
            case .work: return .purple
            case .relationships: return .pink
            case .world: return .teal
            case .gratitude: return .yellow
            case .other: return .gray
            }
        }
    }
}

// MARK: - Prayer Request Service

final class PrayerWallService {
    static let shared = PrayerWallService()

    private let key = "prayerRequests"

    private init() {}

    func loadRequests() -> [PrayerRequest] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let requests = try? JSONDecoder().decode([PrayerRequest].self, from: data)
        else { return [] }
        return requests.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ requests: [PrayerRequest]) {
        if let data = try? JSONEncoder().encode(requests) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func addRequest(text: String, category: PrayerRequest.PrayerCategory) {
        var requests = loadRequests()
        requests.insert(PrayerRequest(text: text, category: category), at: 0)
        save(requests)
    }

    func markAnswered(id: UUID, note: String?) {
        var requests = loadRequests()
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }
        requests[index].isAnswered = true
        requests[index].answeredAt = Date()
        requests[index].answeredNote = note
        save(requests)
    }

    func markPrayed(id: UUID) {
        var requests = loadRequests()
        guard let index = requests.firstIndex(where: { $0.id == id }) else { return }
        requests[index].prayedCount += 1
        requests[index].lastPrayedAt = Date()
        save(requests)
    }

    func deleteRequest(id: UUID) {
        var requests = loadRequests()
        requests.removeAll { $0.id == id }
        save(requests)
    }

    // Stats
    var totalPrayers: Int {
        loadRequests().reduce(0) { $0 + $1.prayedCount }
    }

    var answeredCount: Int {
        loadRequests().filter(\.isAnswered).count
    }

    var activeCount: Int {
        loadRequests().filter { !$0.isAnswered }.count
    }
}
