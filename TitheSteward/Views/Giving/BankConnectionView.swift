import SwiftUI
import SwiftData

struct BankConnectionView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var plaidService = PlaidService()
    @State private var showingUnlinkConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if plaidService.isLinked {
                    linkedStateView
                } else {
                    unlinkedStateView
                }
            }
            .padding()
        }
        .navigationTitle("Bank Connection")
        .onAppear {
            if plaidService.isLinked {
                Task {
                    try? await plaidService.fetchAccounts()
                    let descriptor = FetchDescriptor<UserProfile>()
                    let church = (try? modelContext.fetch(descriptor))?.first?.primaryChurch
                    try? await plaidService.checkForNewIncome(primaryChurch: church)
                }
            }
        }
    }

    // MARK: - Unlinked State

    private var unlinkedStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "building.columns.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Color("AccentGold"))

            Text("Smart Tithe Calculator")
                .font(.title2.bold())

            Text("Connect your bank account to automatically detect income deposits and calculate your tithe. We'll notify you when we see a deposit so you can give with one tap.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // How it works
            VStack(alignment: .leading, spacing: 16) {
                HowItWorksRow(step: "1", title: "Connect securely", description: "Link your bank via Plaid — we never see your credentials")
                HowItWorksRow(step: "2", title: "We detect income", description: "When a paycheck lands, we calculate 10% automatically")
                HowItWorksRow(step: "3", title: "You decide", description: "Tap to give your tithe instantly, or adjust the amount")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)

            Button {
                connectBank()
            } label: {
                Label("Connect Bank Account", systemImage: "link")
                    .accentButtonStyle()
            }

            // Security note
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "lock.shield.fill")
                        .font(.caption)
                    Text("Bank-level encryption")
                        .font(.caption)
                }
                .foregroundColor(.green)

                Text("Powered by Plaid. Read-only access. We never store your bank credentials.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Scripture
            VStack(spacing: 4) {
                Text("\"The plans of the diligent lead to profit as surely as haste leads to poverty.\"")
                    .font(.caption.italic())
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Text("— Proverbs 21:5")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Linked State

    private var linkedStateView: some View {
        VStack(spacing: 20) {
            // Status
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Bank Connected")
                    .font(.headline)
                Spacer()
            }

            // Linked Accounts
            if !plaidService.linkedAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Linked Accounts")
                        .font(.subheadline.bold())

                    ForEach(plaidService.linkedAccounts) { account in
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundColor(Color("AccentGold"))
                            VStack(alignment: .leading) {
                                Text(account.institutionName)
                                    .font(.subheadline)
                                Text("\(account.accountName) ****\(account.accountMask)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            if account.isActive {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .cardStyle()
            }

            // Tithe Suggestion
            if let suggestion = plaidService.pendingTitheSuggestion {
                TitheSuggestionCard(
                    suggestion: suggestion,
                    onGive: {
                        plaidService.markDepositProcessed(suggestion.deposit.id)
                    },
                    onDismiss: {
                        plaidService.dismissSuggestion()
                    }
                )
            }

            // Recent Income Deposits
            if !plaidService.recentIncomeDeposits.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Income")
                        .font(.subheadline.bold())

                    ForEach(plaidService.recentIncomeDeposits.prefix(5)) { deposit in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(deposit.name)
                                    .font(.subheadline)
                                Text(deposit.displayDate)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(deposit.amountDecimal.currencyFormatted)
                                    .font(.subheadline.bold())
                                Text("Tithe: \(deposit.suggestedTithe.currencyFormatted)")
                                    .font(.caption)
                                    .foregroundColor(Color("AccentGold"))
                            }
                        }
                    }
                }
                .cardStyle()
            }

            // Disconnect
            Button(role: .destructive) {
                showingUnlinkConfirm = true
            } label: {
                Label("Disconnect Bank", systemImage: "link.badge.plus")
                    .font(.subheadline)
            }
            .confirmationDialog("Disconnect Bank?", isPresented: $showingUnlinkConfirm) {
                Button("Disconnect", role: .destructive) {
                    Task { try? await plaidService.unlinkBank() }
                }
            } message: {
                Text("This will remove your bank connection. You can always reconnect later.")
            }
        }
    }

    private func connectBank() {
        Task {
            do {
                _ = try await plaidService.createLinkToken()
                // In production, present Plaid Link UI with this token
                // On success, call plaidService.exchangePublicToken(publicToken)
            } catch {
                plaidService.lastError = error.localizedDescription
            }
        }
    }
}

// MARK: - Components

struct HowItWorksRow: View {
    let step: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color("AccentGold"))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TitheSuggestionCard: View {
    let suggestion: PlaidService.TitheSuggestion
    let onGive: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(Color("AccentGold"))
                Text("Tithe Suggestion")
                    .font(.headline)
                Spacer()
                Button { onDismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            Text(suggestion.message)
                .font(.subheadline)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                Button { onGive() } label: {
                    Text("Give \(suggestion.suggestedAmount.currencyFormatted)")
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("AccentGold"))
                        .cornerRadius(10)
                }

                Button { onDismiss() } label: {
                    Text("Not Now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color("AccentGold").opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("AccentGold").opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        BankConnectionView()
    }
}
