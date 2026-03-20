// ChallengeService.swift
// FaithForge
//
// Manages community challenges: joining, contributing XP, and syncing progress.

import Foundation
import SwiftData
import Observation

@Observable
final class ChallengeService {
    private let modelContext: ModelContext

    private(set) var activeChallenges: [CommunityChallenge] = []
    private(set) var joinedChallenges: [CommunityChallenge] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedChallengesIfNeeded()
        refresh()
    }

    // MARK: - Public API

    func refresh() {
        let allDescriptor = FetchDescriptor<CommunityChallenge>(
            sortBy: [SortDescriptor(\.endDate)]
        )
        let all = (try? modelContext.fetch(allDescriptor)) ?? []

        activeChallenges = all.filter { $0.isActive }
        joinedChallenges = all.filter { $0.isJoined && $0.isActive }
    }

    /// Join a community challenge.
    func joinChallenge(_ challenge: CommunityChallenge) {
        guard !challenge.isJoined else { return }
        challenge.isJoined = true
        challenge.participantCount += 1

        // MARK: Firestore Stub
        // In production:
        //
        // let db = Firestore.firestore()
        // let ref = db.collection("challenges").document(challenge.id.uuidString)
        // try await ref.updateData([
        //     "participantCount": FieldValue.increment(Int64(1)),
        //     "participants": FieldValue.arrayUnion([localUserID]),
        // ])

        try? modelContext.save()
        refresh()
    }

    /// Leave a challenge.
    func leaveChallenge(_ challenge: CommunityChallenge) {
        guard challenge.isJoined else { return }
        challenge.isJoined = false
        challenge.participantCount = max(challenge.participantCount - 1, 0)
        try? modelContext.save()
        refresh()
    }

    /// Contribute XP to a joined challenge (called when quests are completed).
    func contributeXP(amount: Int, category: QuestCategory) {
        for challenge in joinedChallenges {
            if challenge.category == category || challenge.type == .epic {
                challenge.myContribution += amount
                challenge.communityXPCurrent += amount

                // Check if community goal is met
                if challenge.communityProgress >= 1.0 && !challenge.isCompleted {
                    challenge.isCompleted = true
                }
            }
        }

        // MARK: Firestore Stub
        // In production:
        //
        // for challenge in joinedChallenges where challenge.category == category {
        //     let ref = db.collection("challenges").document(challenge.id.uuidString)
        //     try await ref.updateData([
        //         "communityXPCurrent": FieldValue.increment(Int64(amount)),
        //     ])
        //     let userRef = ref.collection("participants").document(localUserID)
        //     try await userRef.setData([
        //         "contribution": FieldValue.increment(Int64(amount)),
        //     ], merge: true)
        // }

        try? modelContext.save()
        refresh()
    }

    /// Pull latest challenge data from Firestore.
    func pullFromFirestore() async {
        // MARK: Firestore Pull Stub
        // In production, fetch active challenges and update local SwiftData.

        // Simulate community XP growth for demo
        await MainActor.run {
            for challenge in activeChallenges {
                let randomGrowth = Int.random(in: 50...300)
                challenge.communityXPCurrent = min(
                    challenge.communityXPCurrent + randomGrowth,
                    challenge.communityXPGoal
                )
                // Simulate other participants
                challenge.participantCount = max(challenge.participantCount, Int.random(in: 15...150))
            }
            try? modelContext.save()
            refresh()
        }
    }

    // MARK: - Seed Data

    private func seedChallengesIfNeeded() {
        let descriptor = FetchDescriptor<CommunityChallenge>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for challenge in CommunityChallenge.seedChallenges {
            // Pre-populate with some community progress for demo
            challenge.communityXPCurrent = Int.random(in: 1000...Int(Double(challenge.communityXPGoal) * 0.6))
            challenge.participantCount = Int.random(in: 20...120)
            modelContext.insert(challenge)
        }
        try? modelContext.save()
    }
}
