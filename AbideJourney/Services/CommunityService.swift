import Foundation
import UIKit

/// Handles all community feature communication with the Firebase Cloud Function.
/// Provides shared Prayer Wall and Testimony Wall data across all users.
@MainActor
@Observable
final class CommunityService {
    static let shared = CommunityService()

    var communityPrayers: [CommunityPrayer] = []
    var communityTestimonies: [CommunityTestimony] = []
    var isLoadingPrayers = false
    var isLoadingTestimonies = false
    var pendingTestimonies: [CommunityTestimony] = []
    var flaggedTestimonies: [CommunityTestimony] = []
    var prayedPrayerIDs: Set<String> = []
    var prayedTestimonyIDs: Set<String> = []
    var blockedUserIDs: Set<String> = []

    private let prayedPrayersKey = "community_prayed_prayer_ids"
    private let prayedTestimoniesKey = "community_prayed_testimony_ids"
    private let blockedUsersKey = "community_blocked_user_ids"

    private let baseURL: String? = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "CLOUD_FUNCTION_URL") as? String else {
            return nil
        }
        return url.replacingOccurrences(of: "/generateJourneyHTTP", with: "")
    }()

    private let appSecret: String? = {
        (Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    private var deviceId: String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }

    private init() {
        prayedPrayerIDs = Set(UserDefaults.standard.stringArray(forKey: prayedPrayersKey) ?? [])
        prayedTestimonyIDs = Set(UserDefaults.standard.stringArray(forKey: prayedTestimoniesKey) ?? [])
        blockedUserIDs = Set(UserDefaults.standard.stringArray(forKey: blockedUsersKey) ?? [])
    }

    // MARK: - Content Filtering

    /// Basic profanity/content filter. Returns true if content is acceptable.
    func contentPassesFilter(_ text: String) -> Bool {
        let lowered = text.lowercased()
        let blockedPatterns = [
            "\\bf+u+c+k", "\\bs+h+i+t", "\\ba+s+s+h+o+l+e", "\\bb+i+t+c+h",
            "\\bd+a+m+n", "\\bc+u+n+t", "\\bn+i+g+g", "\\bf+a+g+g",
            "\\bkill\\s+(your|my|him|her)self", "\\bsuicid",
            "\\bhttp[s]?://", "\\bwww\\.",
        ]
        for pattern in blockedPatterns {
            if lowered.range(of: pattern, options: .regularExpression) != nil {
                return false
            }
        }
        return true
    }

    // MARK: - Report & Block

    func reportPrayer(id: String, reason: String) async -> Bool {
        let extra: [String: Any] = ["prayerId": id, "reason": reason]
        let result: SuccessResponse? = await callCommunity(action: "reportPrayer", extra: extra)
        if result?.success == true {
            communityPrayers.removeAll { $0.id == id }
        }
        return result?.success == true
    }

    func reportTestimony(id: String, reason: String) async -> Bool {
        let extra: [String: Any] = ["testimonyId": id, "reason": reason]
        let result: SuccessResponse? = await callCommunity(action: "reportTestimony", extra: extra)
        if result?.success == true {
            communityTestimonies.removeAll { $0.id == id }
        }
        return result?.success == true
    }

    func blockUser(authorId: String) {
        blockedUserIDs.insert(authorId)
        UserDefaults.standard.set(Array(blockedUserIDs), forKey: blockedUsersKey)
        communityPrayers.removeAll { $0.authorId == authorId }
        communityTestimonies.removeAll { $0.authorId == authorId }
    }

    func isUserBlocked(_ authorId: String) -> Bool {
        blockedUserIDs.contains(authorId)
    }

    /// Deletes all community content posted by this device (for account deletion).
    func deleteAllUserContent() async {
        let _: SuccessResponse? = await callCommunity(action: "deleteUserContent")
    }

    // MARK: - Prayer Wall

    func loadCommunityPrayers() async {
        guard !isLoadingPrayers else { return }
        isLoadingPrayers = true
        defer { isLoadingPrayers = false }

        guard let result: PrayerResponse = await callCommunity(action: "getPrayers", extra: ["limit": 50]) else { return }
        communityPrayers = result.prayers.filter { !blockedUserIDs.contains($0.authorId) }
    }

    @discardableResult
    func submitCommunityPrayer(text: String, category: String, authorName: String, isAnonymous: Bool) async -> Bool {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard contentPassesFilter(text) else { return false }
        let extra: [String: Any] = [
            "text": text,
            "category": category,
            "authorName": authorName,
            "isAnonymous": isAnonymous,
        ]
        guard let result: CommunityPrayer = await callCommunity(action: "submitPrayer", extra: extra) else { return false }

        // Add to local list immediately
        communityPrayers.insert(result, at: 0)
        return true
    }

    func prayForRequest(id: String) async {
        guard !prayedPrayerIDs.contains(id) else { return }

        // Optimistic update
        prayedPrayerIDs.insert(id)
        if let index = communityPrayers.firstIndex(where: { $0.id == id }) {
            communityPrayers[index].prayerCount += 1
        }
        savePrayedPrayerIDs()

        let _: SuccessResponse? = await callCommunity(action: "prayForRequest", extra: ["prayerId": id])
    }

    func hasPrayedForPrayer(_ id: String) -> Bool {
        prayedPrayerIDs.contains(id)
    }

    // MARK: - Testimony Wall

    func loadCommunityTestimonies() async {
        guard !isLoadingTestimonies else { return }
        isLoadingTestimonies = true
        defer { isLoadingTestimonies = false }

        guard let result: TestimonyResponse = await callCommunity(action: "getTestimonies", extra: ["limit": 50]) else { return }
        communityTestimonies = result.testimonies.filter { !blockedUserIDs.contains($0.authorId) }
    }

    @discardableResult
    func submitCommunityTestimony(title: String, story: String, category: String, authorName: String, journeyTheme: String, dayCount: Int) async -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !story.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard contentPassesFilter(title), contentPassesFilter(story) else { return false }
        let extra: [String: Any] = [
            "title": title,
            "story": story,
            "category": category,
            "authorName": authorName,
            "journeyTheme": journeyTheme,
            "dayCount": dayCount,
        ]
        guard let result: CommunityTestimony = await callCommunity(action: "submitTestimony", extra: extra) else { return false }
        communityTestimonies.insert(result, at: 0)
        return true
    }

    func prayForTestimony(id: String) async {
        guard !prayedTestimonyIDs.contains(id) else { return }

        prayedTestimonyIDs.insert(id)
        if let index = communityTestimonies.firstIndex(where: { $0.id == id }) {
            communityTestimonies[index].prayerCount += 1
        }
        savePrayedTestimonyIDs()

        let _: SuccessResponse? = await callCommunity(action: "prayForTestimony", extra: ["testimonyId": id])
    }

    func hasPrayedForTestimony(_ id: String) -> Bool {
        prayedTestimonyIDs.contains(id)
    }

    // MARK: - Admin Moderation

    func loadPendingTestimonies() async {
        guard let result: TestimonyResponse = await callCommunity(
            action: "getPendingTestimonies", extra: ["limit": 50]
        ) else { return }
        pendingTestimonies = result.testimonies
    }

    func loadFlaggedTestimonies() async {
        guard let result: TestimonyResponse = await callCommunity(
            action: "getFlaggedTestimonies", extra: ["limit": 50]
        ) else { return }
        flaggedTestimonies = result.testimonies
    }

    @discardableResult
    func approveTestimony(id: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "approveTestimony", extra: ["testimonyId": id]
        )
        if result?.success == true {
            pendingTestimonies.removeAll { $0.id == id }
            flaggedTestimonies.removeAll { $0.id == id }
        }
        return result?.success == true
    }

    @discardableResult
    func deleteTestimonyAsAdmin(id: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "deleteTestimonyAdmin", extra: ["testimonyId": id]
        )
        if result?.success == true {
            pendingTestimonies.removeAll { $0.id == id }
            flaggedTestimonies.removeAll { $0.id == id }
            communityTestimonies.removeAll { $0.id == id }
        }
        return result?.success == true
    }

    // MARK: - User Management (admin)

    func listUsers(filter: String) async -> [UserListItem]? {
        guard let result: UserListResponse = await callCommunity(
            action: "listUsers", extra: ["filter": filter, "limit": 500]
        ) else { return nil }
        return result.users
    }

    func getUserDetail(targetUid: String) async -> UserDetail? {
        return await callCommunity(
            action: "getUserDetail", extra: ["targetUid": targetUid]
        )
    }

    @discardableResult
    func grantPremium(targetUid: String, reason: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "grantPremium", extra: ["targetUid": targetUid, "reason": reason]
        )
        return result?.success == true
    }

    @discardableResult
    func revokePremium(targetUid: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "revokePremium", extra: ["targetUid": targetUid]
        )
        return result?.success == true
    }

    @discardableResult
    func grantAdminClaim(targetUid: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "grantAdminClaim", extra: ["targetUid": targetUid]
        )
        return result?.success == true
    }

    @discardableResult
    func revokeAdminClaim(targetUid: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "revokeAdminClaim", extra: ["targetUid": targetUid]
        )
        return result?.success == true
    }

    @discardableResult
    func deleteUser(targetUid: String) async -> Bool {
        let result: SuccessResponse? = await callCommunity(
            action: "deleteUser", extra: ["targetUid": targetUid]
        )
        return result?.success == true
    }

    // MARK: - Network

    private func callCommunity<T: Decodable>(action: String, extra: [String: Any] = [:]) async -> T? {
        guard let base = baseURL else { return nil }
        guard let url = URL(string: "\(base)/communityHTTP") else { return nil }

        var body: [String: Any] = ["action": action]
        for (key, value) in extra { body[key] = value }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        // New auth: Firebase ID token
        if let token = await AuthService.shared.currentIDToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Legacy fallback for transition window — remove after server-side legacy path is dropped.
        if let secret = appSecret, !secret.isEmpty {
            request.setValue(secret, forHTTPHeaderField: "X-App-Secret")
            body["deviceId"] = deviceId
        }

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                #if DEBUG
                let errorBody = String(data: data.prefix(200), encoding: .utf8) ?? ""
                print("[Community] \(action) failed: \(errorBody)")
                #endif
                return nil
            }
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("[Community] \(action) error: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    // MARK: - Persistence

    private func savePrayedPrayerIDs() {
        UserDefaults.standard.set(Array(prayedPrayerIDs), forKey: prayedPrayersKey)
    }

    private func savePrayedTestimonyIDs() {
        UserDefaults.standard.set(Array(prayedTestimonyIDs), forKey: prayedTestimoniesKey)
    }
}

// MARK: - Community Models

struct CommunityPrayer: Codable, Identifiable {
    let id: String
    let text: String
    let category: String
    let authorId: String
    let authorName: String
    let isAnonymous: Bool
    var prayerCount: Int
    let isAnswered: Bool
    let createdAt: String?

    var relativeDate: String {
        guard let dateStr = createdAt,
              let date = ISO8601DateFormatter().date(from: dateStr) else {
            return "Just now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct CommunityTestimony: Codable, Identifiable {
    let id: String
    let title: String
    let story: String
    let category: String
    let authorId: String
    let authorName: String
    let journeyTheme: String?
    let dayCount: Int?
    var prayerCount: Int
    let isApproved: Bool?
    let isFeatured: Bool?
    let status: String?
    let createdAt: String?

    var relativeDate: String {
        guard let dateStr = createdAt,
              let date = ISO8601DateFormatter().date(from: dateStr) else {
            return "Just now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Response Wrappers

private struct PrayerResponse: Codable {
    let prayers: [CommunityPrayer]
}

private struct TestimonyResponse: Codable {
    let testimonies: [CommunityTestimony]
}

private struct SuccessResponse: Codable {
    let success: Bool
}


// MARK: - User Management Models

struct UserListItem: Codable, Identifiable {
    let id: String
    let email: String?
    let name: String?
    let isAdmin: Bool?
    let createdAt: String?
    let lastSyncedAt: String?
    let premium: PremiumInfo?
}

struct UserListResponse: Codable {
    let users: [UserListItem]
    let total: Int?
}

struct UserDetail: Codable {
    let auth: AuthInfo
    let profile: UserProfileDoc?
    let stats: UserStats

    struct AuthInfo: Codable {
        let uid: String
        let email: String?
        let displayName: String?
        let emailVerified: Bool
        let disabled: Bool
        let providerIds: [String]
        let creationTime: String?
        let lastSignInTime: String?
    }

    struct UserStats: Codable {
        let prayersPosted: Int
        let testimoniesPosted: Int
    }
}

struct UserProfileDoc: Codable {
    let email: String?
    let name: String?
    let isAdmin: Bool?
    let createdAt: String?
    let lastSyncedAt: String?
    let premium: PremiumInfo?
}

struct PremiumInfo: Codable {
    let granted: Bool
    let grantedAt: String?
    let grantedBy: String?
    let reason: String?
    let revokedAt: String?
    let revokedBy: String?
}

