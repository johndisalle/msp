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

        // Push to Firestore via FirebaseService
        Task {
            try? await FirebaseService.shared.joinChallenge(challengeID: challenge.id.uuidString)
        }

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

        // Push to Firestore via FirebaseService
        for challenge in joinedChallenges where challenge.category == category || challenge.type == .epic {
            Task {
                try? await FirebaseService.shared.contributeToChallenge(
                    challengeID: challenge.id.uuidString,
                    xp: amount
                )
            }
        }

        try? modelContext.save()
        refresh()
    }

    /// Pull latest challenge data from Firestore via FirebaseService.
    func pullFromFirestore() async {
        do {
            let remoteChallenges = try await FirebaseService.shared.fetchActiveChallenges()

            await MainActor.run {
                for remote in remoteChallenges {
                    // Try to match by title since IDs may differ between local/remote
                    if let local = activeChallenges.first(where: { $0.title == remote.title }) {
                        local.communityXPCurrent = remote.communityXPCurrent
                        local.communityXPGoal = remote.communityXPGoal
                        local.participantCount = remote.participantCount
                    }
                }
                try? modelContext.save()
                refresh()
            }
        } catch {
            // Fallback: simulate community XP growth for demo
            await MainActor.run {
                for challenge in activeChallenges {
                    let randomGrowth = Int.random(in: 50...300)
                    challenge.communityXPCurrent = min(
                        challenge.communityXPCurrent + randomGrowth,
                        challenge.communityXPGoal
                    )
                    challenge.participantCount = max(challenge.participantCount, Int.random(in: 15...150))
                }
                try? modelContext.save()
                refresh()
            }
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
