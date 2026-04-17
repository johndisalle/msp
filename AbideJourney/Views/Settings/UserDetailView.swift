import SwiftUI

// MARK: - User Detail

struct UserDetailView: View {
    let userId: String
    let initialDisplay: UserListItem?

    @State private var detail: UserDetail?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingGrantSheet = false
    @State private var showingDeleteConfirm = false
    @State private var showingRevokeAdminConfirm = false
    @State private var busyAction: String?

    @Environment(\.dismiss) private var dismiss

    private var community: CommunityService { CommunityService.shared }
    private var isSelf: Bool { userId == AuthService.shared.uid }

    var body: some View {
        List {
            headerSection
            if let detail {
                identitySection(detail)
                statusSection(detail)
                statsSection(detail)
                actionsSection(detail)
            }
            if let errorMessage {
                Section { Text(errorMessage).foregroundStyle(.red) }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(detail?.auth.email ?? initialDisplay?.email ?? "User")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
        .sheet(isPresented: $showingGrantSheet) {
            GrantPremiumSheet { reason in
                await perform("grantPremium") {
                    await community.grantPremium(targetUid: userId, reason: reason)
                }
            }
        }
        .confirmationDialog("Delete this user?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Everything", role: .destructive) {
                Task {
                    await perform("delete") {
                        await community.deleteUser(targetUid: userId)
                    }
                    if errorMessage == nil { dismiss() }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Permanently deletes the user's auth account, Firestore profile, and all community content they've posted. Cannot be undone.")
        }
        .confirmationDialog("Revoke admin?", isPresented: $showingRevokeAdminConfirm, titleVisibility: .visible) {
            Button("Revoke Admin", role: .destructive) {
                Task {
                    await perform("revokeAdmin") {
                        await community.revokeAdminClaim(targetUid: userId)
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This user will lose access to the admin panel. They must restart the app for the change to take effect.")
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        Section {
            if isLoading && detail == nil {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let detail {
                HStack(spacing: 14) {
                    ZStack {
                        Circle().fill(AJTheme.sage.opacity(0.15))
                        Image(systemName: "person.fill")
                            .font(.title3)
                            .foregroundStyle(AJTheme.sage)
                    }
                    .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.auth.email ?? "(no email)")
                            .font(.headline)
                        if let name = detail.auth.displayName, !name.isEmpty {
                            Text(name).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }

    private func identitySection(_ d: UserDetail) -> some View {
        Section("Identity") {
            DetailRow(label: "UID", value: d.auth.uid, monospaced: true)
            DetailRow(label: "Providers", value: d.auth.providerIds.joined(separator: ", "))
            DetailRow(label: "Verified", value: d.auth.emailVerified ? "Yes" : "No")
            DetailRow(label: "Disabled", value: d.auth.disabled ? "Yes" : "No")
        }
    }

    private func statusSection(_ d: UserDetail) -> some View {
        Section("Status") {
            DetailRow(
                label: "Premium",
                value: d.profile?.premium?.granted == true ? "Granted" : "Not granted",
                valueColor: d.profile?.premium?.granted == true ? AJTheme.gold : AJTheme.secondaryText
            )
            if let reason = d.profile?.premium?.reason, d.profile?.premium?.granted == true {
                DetailRow(label: "Reason", value: reason)
            }
            DetailRow(
                label: "Admin",
                value: d.profile?.isAdmin == true ? "Yes" : "No",
                valueColor: d.profile?.isAdmin == true ? AJTheme.sage : AJTheme.secondaryText
            )
            if let created = d.auth.creationTime {
                DetailRow(label: "Created", value: formatDate(created))
            }
            if let lastSignIn = d.auth.lastSignInTime {
                DetailRow(label: "Last sign-in", value: formatDate(lastSignIn))
            }
        }
    }

    private func statsSection(_ d: UserDetail) -> some View {
        Section("Content") {
            DetailRow(label: "Prayers posted", value: "\(d.stats.prayersPosted)")
            DetailRow(label: "Testimonies posted", value: "\(d.stats.testimoniesPosted)")
        }
    }

    @ViewBuilder
    private func actionsSection(_ d: UserDetail) -> some View {
        Section("Actions") {
            // Premium grant/revoke
            if d.profile?.premium?.granted == true {
                Button {
                    Task {
                        await perform("revokePremium") {
                            await community.revokePremium(targetUid: userId)
                        }
                    }
                } label: {
                    Label(
                        busyAction == "revokePremium" ? "Revoking..." : "Revoke Premium",
                        systemImage: "crown.fill"
                    )
                    .foregroundStyle(AJTheme.destructive)
                }
                .disabled(busyAction != nil)
            } else {
                Button {
                    showingGrantSheet = true
                } label: {
                    Label("Grant Premium", systemImage: "crown.fill")
                        .foregroundStyle(AJTheme.gold)
                }
                .disabled(busyAction != nil)
            }

            // Admin grant/revoke
            if d.profile?.isAdmin == true {
                Button {
                    showingRevokeAdminConfirm = true
                } label: {
                    Label(
                        isSelf ? "Revoke Admin (self — blocked)" : "Revoke Admin",
                        systemImage: "shield.slash"
                    )
                    .foregroundStyle(isSelf ? AJTheme.secondaryText : AJTheme.destructive)
                }
                .disabled(isSelf || busyAction != nil)
            } else {
                Button {
                    Task {
                        await perform("grantAdmin") {
                            await community.grantAdminClaim(targetUid: userId)
                        }
                    }
                } label: {
                    Label(
                        busyAction == "grantAdmin" ? "Granting..." : "Grant Admin",
                        systemImage: "shield.lefthalf.filled"
                    )
                    .foregroundStyle(AJTheme.sage)
                }
                .disabled(busyAction != nil)
            }

            // Delete user (destructive, self-blocked)
            Button(role: .destructive) {
                showingDeleteConfirm = true
            } label: {
                Label(
                    isSelf ? "Delete (self — blocked)" : "Delete User",
                    systemImage: "trash"
                )
            }
            .disabled(isSelf || busyAction != nil)
        }
    }

    // MARK: - Helpers

    private func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        if let d = await community.getUserDetail(targetUid: userId) {
            detail = d
        } else {
            errorMessage = "Failed to load user details."
        }
    }

    @MainActor
    private func perform(_ key: String, _ op: () async -> Bool) async {
        busyAction = key
        errorMessage = nil
        let ok = await op()
        busyAction = nil
        if !ok {
            errorMessage = "Action failed — try again."
        } else {
            // Refresh detail to reflect the change
            await load()
        }
    }

    private func formatDate(_ iso: String) -> String {
        let formatters: [ISO8601DateFormatter] = [
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }(),
        ]
        for f in formatters {
            if let d = f.date(from: iso) {
                let out = DateFormatter()
                out.dateStyle = .medium
                out.timeStyle = .short
                return out.string(from: d)
            }
        }
        // Some Auth timestamps are RFC 1123 ("Fri, 17 Apr 2026 14:00:00 GMT")
        let rfc = DateFormatter()
        rfc.locale = Locale(identifier: "en_US_POSIX")
        rfc.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        if let d = rfc.date(from: iso) {
            let out = DateFormatter()
            out.dateStyle = .medium
            out.timeStyle = .short
            return out.string(from: d)
        }
        return iso
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let label: String
    let value: String
    var monospaced: Bool = false
    var valueColor: Color = AJTheme.primaryText

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(AJTheme.secondaryText)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(monospaced ? .caption.monospaced() : .subheadline)
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}

// MARK: - Grant Premium Sheet

private struct GrantPremiumSheet: View {
    let onSubmit: (String) async -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Reason") {
                    TextField("e.g. Beta tester, customer support, gift", text: $reason, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle("Grant Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "..." : "Grant") {
                        Task {
                            isSubmitting = true
                            await onSubmit(reason.trimmingCharacters(in: .whitespacesAndNewlines))
                            isSubmitting = false
                            dismiss()
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
        }
    }
}
