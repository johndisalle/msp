// FirebaseService.swift
// FaithForge
//
// Real Firebase integration: Auth (Apple Sign In) + Firestore (sync, leaderboard, friends, challenges).
//
// SETUP:
// 1. Add firebase-ios-sdk via SPM: https://github.com/firebase/firebase-ios-sdk
//    - Select: FirebaseAuth, FirebaseFirestore
// 2. Add GoogleService-Info.plist to FaithForge target
// 3. Call FirebaseService.configure() in FaithForgeApp.init()
//
// All Firestore methods are behind #if canImport(FirebaseFirestore) so the project
// compiles without the SDK installed. Remove the guards once you add the SDK.

import Foundation
import AuthenticationServices
import Observation
import CryptoKit // For Apple Sign In nonce

// MARK: - Firebase Configuration Check
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@Observable
final class FirebaseService {
    static let shared = FirebaseService()

    // Auth state
    var isSignedIn: Bool = false
    var userID: String?
    var userEmail: String?
    var displayName: String?

    // Nonce for Apple Sign In
    private var currentNonce: String?

    private init() {}

    // MARK: - Configuration

    /// Call in FaithForgeApp.init() after adding firebase-ios-sdk.
    static func configure() {
        FirebaseApp.configure()

        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            shared.isSignedIn = true
            shared.userID = currentUser.uid
            shared.userEmail = currentUser.email
            shared.displayName = currentUser.displayName
        }
    }

    // MARK: - Apple Sign In

    /// Generate a nonce and configure the Apple Sign In request.
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    /// Handle the Apple Sign In result and exchange for Firebase credential.
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let auth):
            guard let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential,
                  let nonce = currentNonce else {
                print("[Firebase] Missing nonce or credential")
                return
            }

            guard let identityTokenData = appleCredential.identityToken,
                  let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
                print("[Firebase] Unable to serialize identity token")
                return
            }

            // Extract user info from first sign-in
            let fullName = [appleCredential.fullName?.givenName, appleCredential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            let email = appleCredential.email

            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleCredential.fullName
            )

            do {
                let authResult = try await Auth.auth().signIn(with: credential)
                let user = authResult.user

                await MainActor.run {
                    self.isSignedIn = true
                    self.userID = user.uid
                    self.userEmail = user.email ?? email
                    self.displayName = user.displayName ?? fullName
                }

                // Create/update user document in Firestore
                try await createOrUpdateUserDocument()

            } catch {
                print("[Firebase] Sign in failed: \(error.localizedDescription)")
            }

        case .failure(let error):
            print("[Firebase] Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    /// Sign out.
    func signOut() {
        try? Auth.auth().signOut()

        isSignedIn = false
        userID = nil
        userEmail = nil
        displayName = nil
    }

    /// Continue without account.
    func continueAsGuest() {
        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                await MainActor.run {
                    self.isSignedIn = true
                    self.userID = result.user.uid
                    self.displayName = "Guest"
                }
            } catch {
                print("[Firebase] Anonymous sign-in failed: \(error)")
            }
        }
    }

    // MARK: - Firestore: User Document

    /// Create or update the user's Firestore document after sign-in.
    func createOrUpdateUserDocument(profile: UserProfileData? = nil) async throws {
        guard let userID else { return }

        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)

        var data: [String: Any] = [
            "lastActive": FieldValue.serverTimestamp(),
        ]

        if let profile {
            data["displayName"] = profile.displayName
            data["totalXP"] = profile.totalXP
            data["weeklyXP"] = profile.weeklyXP
            data["monthlyXP"] = profile.monthlyXP
            data["currentStreak"] = profile.currentStreak
            data["longestStreak"] = profile.longestStreak
            data["level"] = profile.level
        }

        if let email = userEmail {
            data["email"] = email
        }
        if let name = displayName {
            data["displayName"] = name
        }

        try await userRef.setData(data, merge: true)
    }

    // MARK: - Firestore: Leaderboard

    /// Fetch top N leaderboard entries for a given period.
    func fetchLeaderboard(period: String, limit: Int = 50) async throws -> [LeaderboardData] {
        let db = Firestore.firestore()
        let field: String
        switch period {
        case "weekly": field = "weeklyXP"
        case "monthly": field = "monthlyXP"
        default: field = "totalXP"
        }

        let snapshot = try await db.collection("users")
            .order(by: field, descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return LeaderboardData(
                userID: doc.documentID,
                displayName: data["displayName"] as? String ?? "Unknown",
                totalXP: data["totalXP"] as? Int ?? 0,
                weeklyXP: data["weeklyXP"] as? Int ?? 0,
                monthlyXP: data["monthlyXP"] as? Int ?? 0,
                currentStreak: data["currentStreak"] as? Int ?? 0,
                level: data["level"] as? String ?? "Novice"
            )
        }
    }

    // MARK: - Firestore: Friends

    /// Send a friend request.
    func sendFriendRequest(toUserID: String) async throws {
        guard let userID else { return }

        let db = Firestore.firestore()
        try await db.collection("friendRequests").addDocument(data: [
            "from": userID,
            "to": toUserID,
            "status": "pending",
            "createdAt": FieldValue.serverTimestamp(),
        ])
    }

    /// Accept a friend request.
    func acceptFriendRequest(requestID: String) async throws {
        let db = Firestore.firestore()
        let requestRef = db.collection("friendRequests").document(requestID)
        try await requestRef.updateData(["status": "accepted"])

        // Also create bidirectional friend entries
        let requestDoc = try await requestRef.getDocument()
        guard let data = requestDoc.data(),
              let fromUID = data["from"] as? String,
              let toUID = data["to"] as? String else { return }

        let batch = db.batch()
        batch.setData(["friendUID": toUID, "since": FieldValue.serverTimestamp()],
                      forDocument: db.collection("users").document(fromUID).collection("friends").document(toUID))
        batch.setData(["friendUID": fromUID, "since": FieldValue.serverTimestamp()],
                      forDocument: db.collection("users").document(toUID).collection("friends").document(fromUID))
        try await batch.commit()
    }

    /// Fetch the user's friends list.
    func fetchFriends() async throws -> [FriendData] {
        guard let userID else { return [] }

        let db = Firestore.firestore()
        let snapshot = try await db.collection("users").document(userID)
            .collection("friends")
            .getDocuments()

        var friends: [FriendData] = []
        for doc in snapshot.documents {
            let friendUID = doc.data()["friendUID"] as? String ?? ""
            let friendDoc = try await db.collection("users").document(friendUID).getDocument()
            let friendInfo = friendDoc.data() ?? [:]
            friends.append(FriendData(
                userID: friendUID,
                displayName: friendInfo["displayName"] as? String ?? "Unknown",
                totalXP: friendInfo["totalXP"] as? Int ?? 0,
                currentStreak: friendInfo["currentStreak"] as? Int ?? 0,
                level: friendInfo["level"] as? String ?? "Novice"
            ))
        }
        return friends
    }

    // MARK: - Firestore: Challenges

    /// Fetch active community challenges.
    func fetchActiveChallenges() async throws -> [ChallengeData] {
        let db = Firestore.firestore()
        let snapshot = try await db.collection("challenges")
            .whereField("endDate", isGreaterThan: Timestamp(date: Date()))
            .whereField("isActive", isEqualTo: true)
            .order(by: "endDate")
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            return ChallengeData(
                id: doc.documentID,
                title: data["title"] as? String ?? "",
                description: data["description"] as? String ?? "",
                type: data["type"] as? String ?? "Weekly Quest",
                category: data["category"] as? String ?? "The Word",
                communityXPGoal: data["communityXPGoal"] as? Int ?? 10000,
                communityXPCurrent: data["communityXPCurrent"] as? Int ?? 0,
                participantCount: data["participantCount"] as? Int ?? 0,
                bonusXP: data["bonusXP"] as? Int ?? 50,
                startDate: (data["startDate"] as? Timestamp)?.dateValue() ?? Date(),
                endDate: (data["endDate"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
    }

    /// Join a challenge.
    func joinChallenge(challengeID: String) async throws {
        guard let userID else { return }

        let db = Firestore.firestore()
        let challengeRef = db.collection("challenges").document(challengeID)
        try await challengeRef.updateData([
            "participantCount": FieldValue.increment(Int64(1)),
            "participants": FieldValue.arrayUnion([userID]),
        ])
    }

    /// Contribute XP to a challenge.
    func contributeToChallenge(challengeID: String, xp: Int) async throws {
        guard let userID else { return }

        let db = Firestore.firestore()
        let challengeRef = db.collection("challenges").document(challengeID)
        try await challengeRef.updateData([
            "communityXPCurrent": FieldValue.increment(Int64(xp)),
        ])

        let participantRef = challengeRef.collection("participants").document(userID)
        try await participantRef.setData([
            "contribution": FieldValue.increment(Int64(xp)),
            "lastContribution": FieldValue.serverTimestamp(),
        ], merge: true)
    }

    // MARK: - Crypto Helpers (Apple Sign In)

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Data Transfer Objects

/// Lightweight structs for Firestore ↔ SwiftData mapping.

struct UserProfileData {
    let displayName: String
    let totalXP: Int
    let weeklyXP: Int
    let monthlyXP: Int
    let currentStreak: Int
    let longestStreak: Int
    let level: String
}

struct LeaderboardData {
    let userID: String
    let displayName: String
    let totalXP: Int
    let weeklyXP: Int
    let monthlyXP: Int
    let currentStreak: Int
    let level: String
}

struct FriendData {
    let userID: String
    let displayName: String
    let totalXP: Int
    let currentStreak: Int
    let level: String
}

struct ChallengeData {
    let id: String
    let title: String
    let description: String
    let type: String
    let category: String
    let communityXPGoal: Int
    let communityXPCurrent: Int
    let participantCount: Int
    let bonusXP: Int
    let startDate: Date
    let endDate: Date
}
