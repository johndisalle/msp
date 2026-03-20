// SocialTabView.swift
// FaithForge
//
// Container for all social features: Leaderboard, Friends, Challenges.

import SwiftUI

struct SocialTabView: View {
    @Bindable var profile: UserProfile
    @Bindable var leaderboardService: LeaderboardService
    @Bindable var friendService: FriendService
    @Bindable var challengeService: ChallengeService

    @State private var selectedSection: SocialSection = .leaderboard

    enum SocialSection: String, CaseIterable, Identifiable {
        case leaderboard = "Rankings"
        case friends     = "Friends"
        case challenges  = "Challenges"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .leaderboard: return "trophy.fill"
            case .friends:     return "person.2.fill"
            case .challenges:  return "flag.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Section picker
                sectionPicker

                // Content
                Group {
                    switch selectedSection {
                    case .leaderboard:
                        LeaderboardView(leaderboardService: leaderboardService)

                    case .friends:
                        FriendsListView(friendService: friendService)

                    case .challenges:
                        ChallengesView(
                            challengeService: challengeService,
                            profile: profile
                        )
                    }
                }
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("Community")
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 4) {
            ForEach(SocialSection.allCases) { section in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: section.icon)
                            .font(.body)
                        Text(section.rawValue)
                            .font(.caption2.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedSection == section
                            ? Color("FaithBlue").opacity(0.15)
                            : Color.clear
                    )
                    .foregroundStyle(
                        selectedSection == section
                            ? Color("FaithBlue")
                            : .secondary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedSection == section ? .isSelected : [])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color("BackgroundSecondary"))
    }
}
