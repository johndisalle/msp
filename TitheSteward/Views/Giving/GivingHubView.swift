import SwiftUI

struct GivingHubView: View {
    @StateObject private var viewModel = GivingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Give Section
                    VStack(spacing: 12) {
                        HStack {
                            Text("Quick Give")
                                .font(.headline)
                            Spacer()
                            if viewModel.isApplePayAvailable {
                                Image(systemName: "apple.logo")
                                    .foregroundColor(.primary)
                                Text("Pay")
                                    .font(.caption.bold())
                            }
                        }

                        Text("Tap a favorite to give quickly")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if viewModel.favoriteRecipients.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "star.slash")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No favorites yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Add recipients and mark them as favorites for quick giving")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(viewModel.favoriteRecipients) { recipient in
                                    Button {
                                        viewModel.selectedRecipient = recipient
                                        viewModel.showingQuickGive = true
                                    } label: {
                                        VStack(spacing: 8) {
                                            Image(systemName: recipient.type.icon)
                                                .font(.title2)
                                                .foregroundColor(Color("AccentGold"))
                                            Text(recipient.name)
                                                .font(.caption)
                                                .lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

                    // Recurring Giving
                    if !viewModel.recurringGifts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recurring Gifts")
                                    .font(.headline)
                                Spacer()
                                Text(viewModel.formatCurrency(viewModel.monthlyRecurringTotal) + "/mo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            ForEach(viewModel.recurringGifts) { gift in
                                HStack {
                                    Image(systemName: gift.isActive ? "arrow.triangle.2.circlepath.circle.fill" : "pause.circle.fill")
                                        .foregroundColor(gift.isActive ? Color("AccentGold") : .secondary)

                                    VStack(alignment: .leading) {
                                        Text(gift.category.rawValue)
                                            .font(.subheadline)
                                        Text(gift.frequency.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text(viewModel.formatCurrency(gift.amount))
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                        .padding(.horizontal)
                    }

                    // All Recipients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recipients")
                            .font(.headline)

                        if viewModel.recipients.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "person.2.slash")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No recipients added")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                        } else {
                            ForEach(viewModel.recipients) { recipient in
                                HStack {
                                    Image(systemName: recipient.type.icon)
                                        .foregroundColor(Color("AccentGold"))
                                        .frame(width: 24)

                                    VStack(alignment: .leading) {
                                        Text(recipient.name)
                                            .font(.subheadline)
                                        Text(recipient.type.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        viewModel.toggleFavorite(recipient)
                                    } label: {
                                        Image(systemName: recipient.isFavorite ? "star.fill" : "star")
                                            .foregroundColor(recipient.isFavorite ? .yellow : .secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

                    // Scripture
                    VStack(spacing: 8) {
                        Text("\"Remember this: Whoever sows sparingly will also reap sparingly, and whoever sows generously will also reap generously.\"")
                            .font(.callout.italic())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("— 2 Corinthians 9:6")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Giving")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddRecipient = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddRecipient) {
                AddRecipientSheet(viewModel: viewModel)
            }
        }
    }
}

struct AddRecipientSheet: View {
    @ObservedObject var viewModel: GivingViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    TextField("Name", text: $viewModel.newRecipientName)

                    Picker("Type", selection: $viewModel.newRecipientType) {
                        ForEach(RecipientType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }

                Section("Optional") {
                    TextField("Website", text: $viewModel.newRecipientWebsite)
                        .keyboardType(.URL)
                        .textContentType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add Recipient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addRecipient()
                        dismiss()
                    }
                    .disabled(viewModel.newRecipientName.isEmpty)
                }
            }
        }
    }
}

#Preview {
    GivingHubView()
}
