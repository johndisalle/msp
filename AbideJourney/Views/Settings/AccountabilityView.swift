import SwiftUI
import SwiftData

struct AccountabilityView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var partners: [AccountabilityPartner]
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]
    @State private var showingAddSheet = false
    @State private var showingShareSheet = false
    @State private var shareMessage = ""
    @State private var saveError: String?

    private var activeJourney: Journey? {
        journeys.first(where: { $0.isActive && !$0.isCompleted })
    }

    var body: some View {
        List {
            // Progress sharing section
            if let journey = activeJourney {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundStyle(AJTheme.sage)
                            Text("Your Progress")
                                .font(AJTheme.subheadlineFont)
                        }

                        Text("Day \(journey.currentDay) of \(journey.totalDays) — \(journey.theme.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)

                        ProgressView(value: journey.progress)
                            .tint(AJTheme.sage)

                        Button {
                            shareProgress(journey: journey)
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share My Progress")
                            }
                            .font(.subheadline.bold())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(AJTheme.sage.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Journey Progress")
                }
            }

            // Partners list
            Section {
                if partners.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.circle")
                            .font(.largeTitle)
                            .foregroundStyle(AJTheme.secondaryText)

                        Text("No accountability partners yet")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)

                        Text("Invite a trusted friend to encourage each other on your faith journey.")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText.opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                } else {
                    ForEach(partners) { partner in
                        PartnerRow(
                            partner: partner,
                            onSendEncouragement: { sendEncouragement(to: partner) },
                            onMarkActive: { markActive(partner) }
                        )
                    }
                    .onDelete(perform: deletePartners)
                }
            } header: {
                Text("Partners")
            }

            // Tips section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Pray for each other daily", systemImage: "hands.sparkles.fill")
                        .font(.subheadline)
                    Label("Check in weekly on progress", systemImage: "message.fill")
                        .font(.subheadline)
                    Label("Share struggles honestly", systemImage: "heart.fill")
                        .font(.subheadline)
                    Label("Celebrate wins together", systemImage: "party.popper.fill")
                        .font(.subheadline)
                }
                .foregroundStyle(AJTheme.secondaryText)
                .padding(.vertical, 4)
            } header: {
                Text("Tips for Accountability")
            }
        }
        .navigationTitle("Accountability")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddPartnerSheet { name, email in
                addPartner(name: name, email: email)
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [shareMessage])
        }
        .alert("Save Failed", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func addPartner(name: String, email: String) {
        let partner = AccountabilityPartner(name: name, email: email)
        partner.user = profiles.first
        modelContext.insert(partner)
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to add partner. Please try again."
            return
        }

        // Send the invitation via share sheet
        let userName = profiles.first?.name ?? "A friend"
        shareMessage = "Hey \(name)! \(userName) has invited you to be their accountability partner on the Abide Journey app. Walk together through a 40-day faith journey — encourage each other, pray for each other, and grow closer to God. 🙏\n\nDownload Abide Journey to get started!"
        showingShareSheet = true
    }

    private func markActive(_ partner: AccountabilityPartner) {
        partner.status = .active
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to update partner status."
        }
    }

    private func deletePartners(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(partners[index])
        }
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to remove partner. Please try again."
        }
    }

    private func sendEncouragement(to partner: AccountabilityPartner) {
        let userName = profiles.first?.name ?? "Your friend"
        shareMessage = "Hey \(partner.name)! \(userName) is thinking of you and praying for you on the Abide Journey. Keep going strong! 🙏"
        partner.lastEncouragementSent = Date()
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to record encouragement. Please try again."
        }
        showingShareSheet = true
    }

    private func shareProgress(journey: Journey) {
        let userName = profiles.first?.name ?? "I"
        let percentage = Int(journey.progress * 100)
        shareMessage = "\(userName) has completed \(percentage)% of the \(journey.theme.rawValue) journey on Abide Journey! Day \(journey.currentDay) of \(journey.totalDays). 🙏✨"
        showingShareSheet = true
    }
}

// MARK: - Partner Row

struct PartnerRow: View {
    let partner: AccountabilityPartner
    let onSendEncouragement: () -> Void
    var onMarkActive: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(partner.name)
                        .font(.subheadline.bold())
                    Text(partner.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(partner.status.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }

            HStack(spacing: 12) {
                Button {
                    onSendEncouragement()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                        Text("Send Encouragement")
                            .font(.caption)
                    }
                    .foregroundStyle(.accent)
                }

                if partner.status == .invited {
                    Button {
                        onMarkActive()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle")
                                .font(.caption)
                            Text("Mark Active")
                                .font(.caption)
                        }
                        .foregroundStyle(.green)
                    }
                }
            }

            if let lastSent = partner.lastEncouragementSent {
                Text("Last encouraged \(lastSent, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch partner.status {
        case .invited: return .orange
        case .active: return .green
        case .declined: return .red
        }
    }
}

// MARK: - Add Partner Sheet

struct AddPartnerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    let onAdd: (String, String) -> Void

    private var isValidEmail: Bool {
        let pattern = /^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/
        return email.wholeMatch(of: pattern) != nil
    }

    private var emailFooter: String {
        if email.isEmpty {
            return "They'll receive an invitation to join you as an accountability partner."
        } else if !isValidEmail {
            return "Please enter a valid email address."
        }
        return "They'll receive an invitation to join you as an accountability partner."
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("Partner Details")
                } footer: {
                    Text(emailFooter)
                        .foregroundStyle(!email.isEmpty && !isValidEmail ? .red : .secondary)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\"Therefore confess your sins to each other and pray for each other so that you may be healed.\"")
                            .font(.subheadline)
                            .italic()
                        Text("— James 5:16")
                            .font(.caption)
                            .foregroundStyle(.accent)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Add Partner")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Invite") {
                        onAdd(name, email)
                        dismiss()
                    }
                    .bold()
                    .disabled(name.isEmpty || !isValidEmail)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        AccountabilityView()
            .modelContainer(for: AccountabilityPartner.self, inMemory: true)
    }
}
