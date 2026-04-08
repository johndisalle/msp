import Foundation
import UIKit

// MARK: - God Moment Model

struct GodMoment: Codable, Identifiable {
    var id: UUID = UUID()
    var caption: String
    var photoFileName: String
    var createdAt: Date = Date()

    var photoURL: URL? {
        GodMomentsService.storageDir?.appendingPathComponent(photoFileName)
    }
}

// MARK: - God Moments Service

final class GodMomentsService {
    static let shared = GodMomentsService()

    private let key = "godMoments"

    static var storageDir: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("GodMoments", isDirectory: true)
    }

    private init() {
        // Create storage directory
        if let dir = Self.storageDir {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    func loadMoments() -> [GodMoment] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let moments = try? JSONDecoder().decode([GodMoment].self, from: data)
        else { return [] }
        return moments.sorted { $0.createdAt > $1.createdAt }
    }

    func save(_ moments: [GodMoment]) {
        if let data = try? JSONEncoder().encode(moments) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func addMoment(caption: String, image: UIImage) -> GodMoment? {
        guard let dir = Self.storageDir else { return nil }
        let fileName = UUID().uuidString + ".jpg"
        let fileURL = dir.appendingPathComponent(fileName)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        do {
            try data.write(to: fileURL)
        } catch {
            return nil
        }

        let moment = GodMoment(caption: caption, photoFileName: fileName)
        var moments = loadMoments()
        moments.insert(moment, at: 0)
        save(moments)
        return moment
    }

    func deleteMoment(id: UUID) {
        var moments = loadMoments()
        if let moment = moments.first(where: { $0.id == id }),
           let url = moment.photoURL {
            try? FileManager.default.removeItem(at: url)
        }
        moments.removeAll { $0.id == id }
        save(moments)
    }

    func loadImage(for moment: GodMoment) -> UIImage? {
        guard let url = moment.photoURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
