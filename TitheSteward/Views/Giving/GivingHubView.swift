import SwiftUI
import SwiftData

struct GivingHubView: View {
    @StateObject private var viewModel = GivingViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showingGiveNow = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Give Now CTA
                    Button {
                        showingGiveNow = true
                    } label: {
                        HStack {
                            Image(systemName: "heart.circle.fill")
                                .font(.title2)
                            VStack(alignment: .leading) {
                                Text("Give Now")
                                    .font(.headline)
                                Text("Send a gift directly to a church or ministry")
                                    .font(.caption)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AccentGold"))
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)

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
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recurring Gifts")
                                .font(.headline)
                            Spacer()
                            if !viewModel.recurringGifts.isEmpty {
                                Text(viewModel.monthlyRecurringTotal.currencyWhole + "/mo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Button {
                                viewModel.showingAddRecurring = true
                            } label: {
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color("AccentGold"))
                            }
                        }

                        if viewModel.recurringGifts.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("No recurring gifts yet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Set up automated giving to stay consistent")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical)
                        } else {
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

                                    Text(gift.amount.currencyFormatted)
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                    .padding(.horizontal)

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
            .onAppear {
                viewModel.configure(modelContext: modelContext)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showingAddRecipient = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color("AccentGold"))
                    }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button {
                        viewModel.showingAddRecurring = true
                    } label: {
                        Label("Add Recurring Gift", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddRecipient) {
                AddRecipientSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $viewModel.showingAddRecurring) {
                AddRecurringGiftSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingGiveNow) {
                GiveNowView(recipient: viewModel.selectedRecipient)
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

struct AddRecurringGiftSheet: View {
    @ObservedObject var viewModel: GivingViewModel
    @Environment(\.dismiss) var dismiss

    @State private var amount = ""
    @State private var frequency: GiftFrequency = .monthly
    @State private var category: GivingCategory = .tithe
    @State private var startDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Gift Details") {
                    HStack {
                        Text("$")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(GiftFrequency.allCases, id: \.self) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }

                    Picker("Category", selection: $category) {
                        ForEach(GivingCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }

                    DatePicker("First Gift Date", selection: $startDate, displayedComponents: .date)
                }

                if let recipient = viewModel.selectedRecipient {
                    Section {
                        HStack {
                            Image(systemName: recipient.type.icon)
                                .foregroundColor(Color("AccentGold"))
                            Text(recipient.name)
                                .font(.subheadline.bold())
                        }
                    } header: {
                        Text("Recipient")
                    }
                }

                Section {
                    Text("\"On the first day of every week, each one of you should set aside a sum of money in keeping with your income.\"")
                        .font(.caption.italic())
                        .foregroundColor(.secondary)
                    Text("— 1 Corinthians 16:2")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Recurring Gift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Schedule") {
                        viewModel.addRecurringGift(
                            amount: amount,
                            frequency: frequency,
                            category: category,
                            startDate: startDate
                        )
                        dismiss()
                    }
                    .disabled(amount.isEmpty || viewModel.selectedRecipient == nil)
                }
            }
        }
    }
}

#Preview {
    GivingHubView()
}
