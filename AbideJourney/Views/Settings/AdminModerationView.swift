import SwiftUI

// MARK: - Admin Moderation Queue
//
// Visible only when AuthService.shared.isAdmin == true.
// Two tabs: Pending (awaiting first-time approval) and Flagged
// (was approved, then auto-hidden by 3+ user reports).

struct AdminModerationView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case pending = "Pending"
        case flagged = "Flagged"
        var id: Self { self }
    }

    @State private var tab: Tab = .pending
    @State private var isLoading = false

    private var community: CommunityService { CommunityService.shared }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Queue", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding()

            content
        }
        .navigationTitle("Moderation")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: tab) { await load() }
        .refreshable { await load() }
    }

    @ViewBuilder
    private var content: some View {
        let items: [CommunityTestimony] = (tab == .pending)
            ? community.pendingTestimonies
            : community.flaggedTestimonies

        if isLoading && items.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if items.isEmpty {
            emptyState
        } else {
            List {
                ForEach(items) { t in
                    TestimonyReviewRow(testimony: t)
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 48))
                .foregroundStyle(AJTheme.sage)
            Text(tab == .pending ? "Nothing pending" : "Nothing flagged")
                .font(.headline)
            Text(tab == .pending
                 ? "New submissions show up here for review."
                 : "Testimonies auto-hidden by user reports appear here.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        switch tab {
        case .pending: await community.loadPendingTestimonies()
        case .flagged: await community.loadFlaggedTestimonies()
        }
    }
}

// MARK: - Review Row

private struct TestimonyReviewRow: View {
    let testimony: CommunityTestimony

    @State private var isBusy = false
    @State private var errorMessage: String?

    private var community: CommunityService { CommunityService.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(testimony.title)
                    .font(.headline)
                    .foregroundStyle(AJTheme.primaryText)
                Spacer()
                Text(testimony.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AJTheme.sage)
                Text(testimony.authorName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(testimony.category)
                    .font(.caption2)
                    .foregroundStyle(AJTheme.gold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(AJTheme.gold.opacity(0.1))
                    .clipShape(Capsule())
            }

            Text(testimony.story)
                .font(.body)
                .foregroundStyle(AJTheme.primaryText)
                .lineSpacing(3)

            HStack(spacing: 12) {
                Button {
                    Task { await act(.approve) }
                } label: {
                    Label("Approve", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(AJTheme.sage)
                .disabled(isBusy)

                Button(role: .destructive) {
                    Task { await act(.delete) }
                } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isBusy)
            }
            .padding(.top, 4)

            if let msg = errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.vertical, 6)
    }

    private enum Action { case approve, delete }

    private func act(_ action: Action) async {
        isBusy = true
        errorMessage = nil
        defer { isBusy = false }

        let success: Bool
        switch action {
        case .approve: success = await community.approveTestimony(id: testimony.id)
        case .delete:  success = await community.deleteTestimonyAsAdmin(id: testimony.id)
        }
        if !success {
            errorMessage = "Action failed — try again."
        }
    }
}

#Preview {
    NavigationStack {
        AdminModerationView()
    }
}
