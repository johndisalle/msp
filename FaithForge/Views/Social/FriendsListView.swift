// FriendsListView.swift
// FaithForge
//
// Friends list, pending requests, and add friend sheet.

import SwiftUI

struct FriendsListView: View {
    @Bindable var friendService: FriendService
    @State private var showAddFriend = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pending Requests
                if !friendService.pendingRequests.isEmpty {
                    pendingSection
                }

                // Friends List
                friendsSection

                // Add Friend Button
                addFriendButton
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
        .sheet(isPresented: $showAddFriend) {
            AddFriendSheet(friendService: friendService)
        }
        .refreshable {
            await friendService.syncFriendData()
        }
    }

    // MARK: - Pending Requests

    private var pendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Pending Requests", systemImage: "bell.badge.fill")
                .font(.headline)
                .foregroundStyle(Color("FaithWarm"))

            ForEach(friendService.pendingRequests, id: \.id) { request in
                PendingRequestRow(
                    request: request,
                    onAccept: { friendService.acceptRequest(request) },
                    onDecline: { friendService.declineRequest(request) }
                )
            }
        }
    }

    // MARK: - Friends List

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Friends", systemImage: "person.2.fill")
                    .font(.headline)
                    .foregroundStyle(Color("TextPrimary"))

                Spacer()

                Text("\(friendService.friends.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if friendService.friends.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("No friends yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Add friends to see their progress and cheer each other on!")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                ForEach(friendService.friends, id: \.id) { friend in
                    FriendRow(friend: friend) {
                        friendService.removeFriend(friend)
                    }
                }
            }
        }
    }

    // MARK: - Add Friend Button

    private var addFriendButton: some View {
        Button {
            showAddFriend = true
        } label: {
            Label("Add Friend", systemImage: "person.badge.plus")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("FaithBlue"))
    }
}

// MARK: - Pending Request Row

private struct PendingRequestRow: View {
    let request: FriendConnection
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: request.friendAvatarSymbol)
                .font(.title2)
                .foregroundStyle(Color("FaithBlue"))
                .frame(width: 40, height: 40)
                .background(Color("FaithBlue").opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(request.friendDisplayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("TextPrimary"))

                Text(request.isSentByMe ? "Request sent" : "Wants to connect")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !request.isSentByMe {
                Button(action: onAccept) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color("FaithGreen"))
                }

                Button(action: onDecline) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Pending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .faithCard()
    }
}

// MARK: - Friend Row

private struct FriendRow: View {
    let friend: FriendConnection
    let onRemove: () -> Void

    @State private var showRemoveConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: friend.friendAvatarSymbol)
                .font(.title2)
                .foregroundStyle(Color("FaithGreen"))
                .frame(width: 40, height: 40)
                .background(Color("FaithGreen").opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.friendDisplayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("TextPrimary"))

                HStack(spacing: 8) {
                    Label("\(friend.friendLevel.rawValue)", systemImage: friend.friendLevel.icon)
                    if friend.friendCurrentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                            Text("\(friend.friendCurrentStreak)")
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(friend.friendTotalXP)")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("TextPrimary"))
                Text("XP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .faithCard()
        .contextMenu {
            Button(role: .destructive) {
                showRemoveConfirm = true
            } label: {
                Label("Remove Friend", systemImage: "person.badge.minus")
            }
        }
        .confirmationDialog(
            "Remove \(friend.friendDisplayName)?",
            isPresented: $showRemoveConfirm,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive, action: onRemove)
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Add Friend Sheet

struct AddFriendSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var friendService: FriendService

    @State private var friendCode: String = ""
    @State private var friendName: String = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(Color("FaithBlue"))
                    .padding(.top, 24)

                Text("Add a Friend")
                    .font(.title2.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("Enter your friend's FaithForge ID or share code to connect.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 16) {
                    TextField("Friend's Name", text: $friendName)
                        .textFieldStyle(.roundedBorder)

                    TextField("Friend Code or User ID", text: $friendCode)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 24)

                if showSuccess {
                    Label("Request sent!", systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(Color("FaithGreen"))
                }

                Spacer()

                Button {
                    sendRequest()
                } label: {
                    Text("Send Friend Request")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("FaithBlue"))
                .disabled(friendCode.isEmpty || friendName.isEmpty)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func sendRequest() {
        friendService.sendFriendRequest(
            friendUserID: friendCode,
            friendName: friendName
        )
        showSuccess = true
        friendCode = ""
        friendName = ""
    }
}
