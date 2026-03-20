// LeaderboardService.swift
// FaithForge
//
// Manages leaderboard data sync. Uses local SwiftData with Firestore sync stubs.
// Replace stubbed Firestore calls when adding firebase-ios-sdk.

import Foundation
import SwiftData
import Observation

@Observable
final class LeaderboardService {
    private let modelContext: ModelContext

    private(set) var rankings: [LeaderboardEntry] = []
    private(set) var isLoading: Bool = false
    var selectedPeriod: LeaderboardPeriod = .weekly

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedDemoDataIfNeeded()
        fetchRankings()
    }

    // MARK: - Public API

    /// Refresh rankings for the selected period.
    func fetchRankings() {
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            sortBy: [SortDescriptor(\.weeklyXP, order: .reverse)]
        )
        let all = (try? modelContext.fetch(descriptor)) ?? []

        // Sort by selected period
        rankings = all.sorted { a, b in
            a.xp(for: selectedPeriod) > b.xp(for: selectedPeriod)
        }
    }

    /// Sync the local user's profile to the leaderboard.
    func syncLocalProfile(_ profile: UserProfile, userID: String) {
        let descriptor = FetchDescriptor<LeaderboardEntry>(
            predicate: #Predicate<LeaderboardEntry> { $0.isCurrentUser }
        )
        let existing = try? modelContext.fetch(descriptor)

        let entry: LeaderboardEntry
        if let found = existing?.first {
            entry = found
        } else {
            entry = LeaderboardEntry(
                userID: userID,
                displayName: profile.displayName,
                isCurrentUser: true
            )
            modelContext.insert(entry)
        }

        entry.displayName = profile.displayName
        entry.totalXP = profile.totalXP
        entry.currentStreak = profile.currentStreak
        entry.levelRaw = profile.level.rawValue
        entry.lastSyncDate = Date()

        // TODO: Calculate weekly/monthly XP from FaithRingProgress history
        // For now, use a fraction of total XP as placeholder
        entry.weeklyXP = min(profile.totalXP, 500)
        entry.monthlyXP = min(profile.totalXP, 2000)

        try? modelContext.save()

        // MARK: Firestore Sync Stub
        // In production, push to Firestore:
        //
        // let db = Firestore.firestore()
        // try await db.collection("leaderboard").document(userID).setData([
        //     "displayName": entry.displayName,
        //     "totalXP": entry.totalXP,
        //     "weeklyXP": entry.weeklyXP,
        //     "monthlyXP": entry.monthlyXP,
        //     "currentStreak": entry.currentStreak,
        //     "level": entry.levelRaw,
        //     "lastSync": FieldValue.serverTimestamp(),
        // ], merge: true)

        fetchRankings()
    }

    /// Pull latest leaderboard data from Firestore.
    func pullFromFirestore() async {
        await MainActor.run { isLoading = true }

        // MARK: Firestore Pull Stub
        // In production:
        //
        // let db = Firestore.firestore()
        // let snapshot = try await db.collection("leaderboard")
        //     .order(by: "weeklyXP", descending: true)
        //     .limit(to: 50)
        //     .getDocuments()
        //
        // for doc in snapshot.documents {
        //     let data = doc.data()
        //     // Upsert into SwiftData
        // }

        // Simulate network delay for demo
        try? await Task.sleep(for: .seconds(1))

        await MainActor.run {
            isLoading = false
            fetchRankings()
        }
    }

    /// Get the rank position for the current user.
    var currentUserRank: Int? {
        guard let index = rankings.firstIndex(where: { $0.isCurrentUser }) else { return nil }
        return index + 1
    }

    // MARK: - Demo Data

    private func seedDemoDataIfNeeded() {
        let descriptor = FetchDescriptor<LeaderboardEntry>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        let demoUsers: [(String, String, Int, Int, Int, Int, String)] = [
            ("demo-1", "Sarah M.",    4200, 380, 1600, 21, "person.crop.circle.fill"),
            ("demo-2", "David K.",    3800, 340, 1450, 18, "person.crop.circle.fill"),
            ("demo-3", "Grace L.",    3100, 290, 1200, 14, "person.crop.circle.fill"),
            ("demo-4", "James W.",    2500, 220, 950,  10, "person.crop.circle.fill"),
            ("demo-5", "Ruth P.",     2100, 180, 800,  7,  "person.crop.circle.fill"),
            ("demo-6", "Paul A.",     1800, 150, 700,  12, "person.crop.circle.fill"),
            ("demo-7", "Esther C.",   1400, 120, 550,  5,  "person.crop.circle.fill"),
            ("demo-8", "Daniel F.",   1100, 90,  400,  9,  "person.crop.circle.fill"),
            ("demo-9", "Mary H.",     800,  70,  300,  3,  "person.crop.circle.fill"),
            ("demo-10", "John B.",    500,  40,  180,  2,  "person.crop.circle.fill"),
        ]

        for (uid, name, total, weekly, monthly, streak, avatar) in demoUsers {
            let entry = LeaderboardEntry(
                userID: uid,
                displayName: name,
                totalXP: total,
                weeklyXP: weekly,
                monthlyXP: monthly,
                currentStreak: streak,
                level: FaithLevel.allCases.last { total >= $0.xpThreshold } ?? .novice,
                avatarSymbol: avatar
            )
            modelContext.insert(entry)
        }
        try? modelContext.save()
    }
}

// MARK: - Comparable helper for FaithLevel
private extension FaithLevel {
    static func allCasesWhere(_ predicate: (FaithLevel) -> Bool) -> [FaithLevel] {
        allCases.filter(predicate)
    }
}

private extension Array where Element: CaseIterable & Equatable {
    func last(where predicate: (Element) -> Bool) -> Element? {
        self.reversed().first(where: predicate)
    }
}
