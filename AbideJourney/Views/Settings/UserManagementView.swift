import SwiftUI

// MARK: - User Management

struct UserManagementView: View {
    enum Filter: String, CaseIterable, Identifiable {
        case all = "All"
        case premium = "Premium"
        case admin = "Admins"
        case recent = "Recent"
        var id: Self { self }

        var serverValue: String {
            switch self {
            case .all: return "all"
            case .premium: return "premium"
            case .admin: return "admin"
            case .recent: return "recent"
            }
        }
    }

    @State private var filter: Filter = .all
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var users: [UserListItem] = []
    @State private var errorMessage: String?

    private var community: CommunityService { CommunityService.shared }

    var body: some View {
        VStack(spacing: 0) {
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Filter.allCases) { f in
                        FilterChip(
                            label: f.rawValue,
                            isSelected: filter == f
                        ) {
                            filter = f
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)

            Divider()

            content
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search email, name, or UID")
        .task(id: filter) { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        let shown = filtered(users)

        if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .padding()
        } else if isLoading && users.isEmpty {
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if shown.isEmpty {
            ContentUnavailableView(
                searchText.isEmpty ? "No users" : "No matches",
                systemImage: "person.crop.circle.badge.questionmark",
                description: Text(searchText.isEmpty
                    ? "No users match this filter."
                    : "Try a different search term.")
            )
        } else {
            List {
                Section {
                    ForEach(shown) { u in
                        NavigationLink {
                            UserDetailView(userId: u.id, initialDisplay: u)
                        } label: {
                            UserRow(user: u)
                        }
                    }
                } header: {
                    Text("\(shown.count) \(shown.count == 1 ? "user" : "users")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func filtered(_ input: [UserListItem]) -> [UserListItem] {
        let q = searchText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return input }
        return input.filter { u in
            u.email?.lowercased().contains(q) == true ||
            u.name?.lowercased().contains(q) == true ||
            u.id.lowercased().contains(q)
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        if let list = await community.listUsers(filter: filter.serverValue) {
            users = list
        } else {
            errorMessage = "Failed to load users."
        }
    }
}

// MARK: - User Row

private struct UserRow: View {
    let user: UserListItem

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(AJTheme.sage.opacity(0.12))
                Text(initials)
                    .font(.caption.bold())
                    .foregroundStyle(AJTheme.sage)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(user.email ?? "(no email)")
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.primaryText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if user.premium?.granted == true {
                        Label("Premium", systemImage: "crown.fill")
                            .labelStyle(.iconOnly)
                            .font(.caption2)
                            .foregroundStyle(AJTheme.gold)
                    }
                    if user.isAdmin == true {
                        Label("Admin", systemImage: "shield.lefthalf.filled")
                            .labelStyle(.iconOnly)
                            .font(.caption2)
                            .foregroundStyle(AJTheme.sage)
                    }
                    Text(user.id.prefix(12) + "…")
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.vertical, 2)
    }

    private var initials: String {
        let source = user.name?.isEmpty == false ? user.name! : (user.email ?? "?")
        let parts = source.split(separator: " ").prefix(2)
        let letters = parts.compactMap { $0.first }.map { String($0).uppercased() }.joined()
        return letters.isEmpty ? String(source.prefix(1)).uppercased() : letters
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? AJTheme.sage : AJTheme.sage.opacity(0.08))
                )
                .foregroundStyle(isSelected ? Color.white : AJTheme.sage)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { UserManagementView() }
}
