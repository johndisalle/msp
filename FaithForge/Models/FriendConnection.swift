// FriendConnection.swift
// FaithForge
//
// Data model for friend relationships and accountability partners.

import Foundation
import SwiftData

/// Status of a friend request/connection.
enum FriendStatus: String, Codable {
    case pending  = "Pending"
    case accepted = "Accepted"
    case declined = "Declined"
}

@Model
final class FriendConnection {
    var id: UUID = UUID()
    /// The remote user ID of the friend.
    var friendUserID: String = ""
    var friendDisplayName: String = ""
    var friendAvatarSymbol: String = "person.crop.circle.fill"
    var statusRaw: String = FriendStatus.pending.rawValue
    var friendTotalXP: Int = 0
    var friendCurrentStreak: Int = 0
    var friendLevelRaw: String = FaithLevel.novice.rawValue
    /// Whether the local user sent the request (vs received).
    var isSentByMe: Bool = true
    var createdAt: Date = Date()
    var lastUpdated: Date = Date()

    init(
        friendUserID: String,
        friendDisplayName: String,
        friendAvatarSymbol: String = "person.crop.circle.fill",
        isSentByMe: Bool = true
    ) {
        self.id = UUID()
        self.friendUserID = friendUserID
        self.friendDisplayName = friendDisplayName
        self.friendAvatarSymbol = friendAvatarSymbol
        self.isSentByMe = isSentByMe
        self.createdAt = Date()
        self.lastUpdated = Date()
    }

    var status: FriendStatus {
        get { FriendStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var friendLevel: FaithLevel {
        FaithLevel(rawValue: friendLevelRaw) ?? .novice
    }
}
