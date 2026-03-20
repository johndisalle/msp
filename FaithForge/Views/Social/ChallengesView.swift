// ChallengesView.swift
// FaithForge
//
// Community challenges: browse, join, track progress.

import SwiftUI

struct ChallengesView: View {
    @Bindable var challengeService: ChallengeService
    @Bindable var profile: UserProfile

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Joined Challenges
                if !challengeService.joinedChallenges.isEmpty {
                    joinedSection
                }

                // Available Challenges
                availableSection
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .refreshable {
            await challengeService.pullFromFirestore()
        }
    }

    // MARK: - Joined Challenges

    private var joinedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("My Challenges", systemImage: "flag.fill")
                .font(.headline)
                .foregroundStyle(Color("FaithGold"))

            ForEach(challengeService.joinedChallenges, id: \.id) { challenge in
                JoinedChallengeCard(challenge: challenge) {
                    challengeService.leaveChallenge(challenge)
                }
            }
        }
    }

    // MARK: - Available Challenges

    private var availableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Community Challenges", systemImage: "person.3.fill")
                .font(.headline)
                .foregroundStyle(Color("TextPrimary"))

            if challengeService.activeChallenges.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "trophy")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No active challenges right now")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(challengeService.activeChallenges, id: \.id) { challenge in
                    ChallengeCard(challenge: challenge) {
                        challengeService.joinChallenge(challenge)
                    }
                }
            }
        }
    }
}

// MARK: - Challenge Card (Available)

private struct ChallengeCard: View {
    let challenge: CommunityChallenge
    let onJoin: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: challenge.type.icon)
                    .font(.title3)
                    .foregroundStyle(typeColor)
                    .frame(width: 36, height: 36)
                    .background(typeColor.opacity(0.15))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.title)
                        .font(.headline)
                        .foregroundStyle(Color("TextPrimary"))

                    HStack(spacing: 8) {
                        Label(challenge.type.rawValue, systemImage: "clock")
                        Text("\u{2022}")
                        Label(challenge.category.rawValue, systemImage: challenge.category.icon)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                // Days remaining
                VStack(spacing: 1) {
                    Text("\(challenge.daysRemaining)")
                        .font(.title3.bold())
                        .foregroundStyle(Color("TextPrimary"))
                    Text("days left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Description
            Text(challenge.challengeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            // Community Progress Bar
            VStack(spacing: 6) {
                ProgressView(value: challenge.communityProgress)
                    .tint(typeColor)

                HStack {
                    Text("\(challenge.communityXPCurrent) / \(challenge.communityXPGoal) XP")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Label("\(challenge.participantCount) joined", systemImage: "person.2")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Join Button / Status
            HStack {
                Label("+\(challenge.bonusXP) XP Bonus", systemImage: "star.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color("FaithGold"))

                Spacer()

                if challenge.isJoined {
                    Label("Joined", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("FaithGreen"))
                } else {
                    Button(action: onJoin) {
                        Text("Join Challenge")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(typeColor)
                }
            }
        }
        .faithCard()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(challenge.title), \(challenge.type.rawValue) challenge, \(Int(challenge.communityProgress * 100)) percent complete, \(challenge.daysRemaining) days remaining, \(challenge.participantCount) participants")
    }

    private var typeColor: Color {
        switch challenge.type {
        case .daily:  return Color("FaithBlue")
        case .weekly: return Color("FaithGreen")
        case .epic:   return Color("FaithGold")
        }
    }
}

// MARK: - Joined Challenge Card (compact, with personal progress)

private struct JoinedChallengeCard: View {
    let challenge: CommunityChallenge
    let onLeave: () -> Void

    @State private var showLeaveConfirm = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: challenge.type.icon)
                    .foregroundStyle(Color("FaithGold"))

                Text(challenge.title)
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                Text("\(challenge.daysRemaining)d left")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Community progress
            VStack(spacing: 4) {
                ProgressView(value: challenge.communityProgress)
                    .tint(Color("FaithGreen"))

                HStack {
                    Text("Community: \(Int(challenge.communityProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("My contribution: \(challenge.myContribution) XP")
                        .font(.caption2)
                        .foregroundStyle(Color("FaithBlue"))
                }
            }
        }
        .faithCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color("FaithGold").opacity(0.3), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(challenge.title), community progress \(Int(challenge.communityProgress * 100)) percent, your contribution \(challenge.myContribution) XP, \(challenge.daysRemaining) days left")
        .contextMenu {
            Button(role: .destructive) {
                showLeaveConfirm = true
            } label: {
                Label("Leave Challenge", systemImage: "xmark.circle")
            }
        }
        .confirmationDialog(
            "Leave \(challenge.title)?",
            isPresented: $showLeaveConfirm,
            titleVisibility: .visible
        ) {
            Button("Leave", role: .destructive, action: onLeave)
            Button("Cancel", role: .cancel) {}
        }
    }
}
