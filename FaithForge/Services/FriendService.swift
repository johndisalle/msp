// FriendService.swift
// FaithForge
//
// Manages friend connections: add, accept, remove, and sync friend data.

import Foundation
import SwiftData
import Observation

@Observable
final class FriendService {
    private let modelContext: ModelContext

    private(set) var friends: [FriendConnection] = []
    private(set) var pendingRequests: [FriendConnection] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedDemoFriendsIfNeeded()
        refresh()
    }

    // MARK: - Public API

    func refresh() {
        let acceptedPredicate = #Predicate<FriendConnection> { $0.statusRaw == "Accepted" }
        let acceptedDescriptor = FetchDescriptor<FriendConnection>(
            predicate: acceptedPredicate,
            sortBy: [SortDescriptor(\.friendDisplayName)]
        )
        friends = (try? modelContext.fetch(acceptedDescriptor)) ?? []

        let pendingPredicate = #Predicate<FriendConnection> { $0.statusRaw == "Pending" }
        let pendingDescriptor = FetchDescriptor<FriendConnection>(
            predicate: pendingPredicate,
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        pendingRequests = (try? modelContext.fetch(pendingDescriptor)) ?? []
    }

    /// Send a friend request by friend code / user ID.
    func sendFriendRequest(friendUserID: String, friendName: String) {
        // Check for duplicate
        let allDescriptor = FetchDescriptor<FriendConnection>()
        let all = (try? modelContext.fetch(allDescriptor)) ?? []
        if all.contains(where: { $0.friendUserID == friendUserID }) { return }

        let connection = FriendConnection(
            friendUserID: friendUserID,
            friendDisplayName: friendName,
            isSentByMe: true
        )
        modelContext.insert(connection)

        // Push to Firestore via FirebaseService
        Task {
            try? await FirebaseService.shared.sendFriendRequest(toUserID: friendUserID)
        }

        try? modelContext.save()
        refresh()
    }

    /// Accept a pending friend request.
    func acceptRequest(_ connection: FriendConnection) {
        connection.status = .accepted
        connection.lastUpdated = Date()
        try? modelContext.save()
        refresh()
    }

    /// Decline a pending friend request.
    func declineRequest(_ connection: FriendConnection) {
        connection.status = .declined
        connection.lastUpdated = Date()
        try? modelContext.save()
        refresh()
    }

    /// Remove an existing friend.
    func removeFriend(_ connection: FriendConnection) {
        modelContext.delete(connection)
        try? modelContext.save()
        refresh()
    }

    /// Sync friend data from Firestore via FirebaseService.
    func syncFriendData() async {
        do {
            let remoteFriends = try await FirebaseService.shared.fetchFriends()
            await MainActor.run {
                for remote in remoteFriends {
                    if let local = friends.first(where: { $0.friendUserID == remote.userID }) {
                        local.friendTotalXP = remote.totalXP
                        local.friendCurrentStreak = remote.currentStreak
                        local.friendLevelRaw = remote.level
                    }
                }
                try? modelContext.save()
                refresh()
            }
        } catch {
            // Fallback: no-op when Firebase SDK isn't wired
            try? await Task.sleep(for: .seconds(0.5))
            await MainActor.run { refresh() }
        }
    }

    // MARK: - Demo Data

    private func seedDemoFriendsIfNeeded() {
        let descriptor = FetchDescriptor<FriendConnection>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let demoFriends: [(String, String, Int, Int, FriendStatus)] = [
            ("demo-1", "Sarah M.",  4200, 21, .accepted),
            ("demo-2", "David K.",  3800, 18, .accepted),
            ("demo-3", "Grace L.",  3100, 14, .accepted),
            ("demo-7", "Esther C.", 1400, 5,  .pending),
        ]

        for (uid, name, xp, streak, status) in demoFriends {
            let conn = FriendConnection(
                friendUserID: uid,
                friendDisplayName: name
            )
            conn.status = status
            conn.friendTotalXP = xp
            conn.friendCurrentStreak = streak
            conn.isSentByMe = status == .accepted
            modelContext.insert(conn)
        }
        try? modelContext.save()
    }
}
