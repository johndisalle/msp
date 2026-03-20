import SwiftUI
import SwiftData
import PassKit

struct GiveNowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var stripeService = StripeConnectService()

    let recipient: GivingRecipient?

    @State private var amount = ""
    @State private var category: GivingCategory = .tithe
    @State private var searchQuery = ""
    @State private var searchResults: [StripeConnectService.ConnectedAccount] = []
    @State private var selectedAccount: StripeConnectService.ConnectedAccount?
    @State private var isSearching = false
    @State private var showingApplePay = false
    @State private var showingSuccess = false
    @State private var paymentError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Amount
                    VStack(spacing: 8) {
                        Text("Gift Amount")
                            .font(.headline)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("$")
                                .font(.system(size: 40, weight: .light))
                                .foregroundColor(.secondary)
                            TextField("0", text: $amount)
                                .font(.system(size: 56, weight: .bold))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)

                        // Quick amounts
                        HStack(spacing: 12) {
                            ForEach(["25", "50", "100", "500"], id: \.self) { quickAmount in
                                Button {
                                    amount = quickAmount
                                } label: {
                                    Text("$\(quickAmount)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(amount == quickAmount ? .white : Color("AccentGold"))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(amount == quickAmount ? Color("AccentGold") : Color("AccentGold").opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    // Category
                    Picker("Category", selection: $category) {
                        ForEach(GivingCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)

                    // Recipient
                    if let recipient = recipient {
                        HStack {
                            Image(systemName: recipient.type.icon)
                                .foregroundColor(Color("AccentGold"))
                            Text(recipient.name)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    } else {
                        // Search for connected ministries
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Search Ministries")
                                .font(.headline)

                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                TextField("Church or ministry name", text: $searchQuery)
                                    .textFieldStyle(.plain)
                                    .onSubmit { searchMinistries() }

                                if isSearching {
                                    ProgressView()
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                            ForEach(searchResults) { account in
                                Button {
                                    selectedAccount = account
                                } label: {
                                    HStack {
                                        Image(systemName: "building.columns.fill")
                                            .foregroundColor(Color("AccentGold"))
                                        VStack(alignment: .leading) {
                                            Text(account.name)
                                                .font(.subheadline.bold())
                                                .foregroundColor(.primary)
                                            if account.isVerified {
                                                Label("Verified", systemImage: "checkmark.seal.fill")
                                                    .font(.caption2)
                                                    .foregroundColor(.green)
                                            }
                                        }
                                        Spacer()
                                        if selectedAccount?.id == account.id {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }

                    // Processing fee note
                    if let amountDecimal = Decimal(string: amount), amountDecimal > 0 {
                        let fee = amountDecimal * StripeConnectService.platformFeePercent
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("Processing fee: \(fee.currencyFormatted) (\(NSDecimalNumber(decimal: StripeConnectService.platformFeePercent * 100).stringValue)%)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Pay Button
                    if GivingService.isApplePayAvailable {
                        Button {
                            processApplePayGift()
                        } label: {
                            HStack {
                                Image(systemName: "apple.logo")
                                Text("Pay")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.black)
                            .cornerRadius(14)
                        }
                        .disabled(amount.isEmpty || (recipient == nil && selectedAccount == nil))
                    }

                    Button {
                        processCardGift()
                    } label: {
                        Label("Give with Card", systemImage: "creditcard.fill")
                            .accentButtonStyle()
                    }
                    .disabled(amount.isEmpty || (recipient == nil && selectedAccount == nil))

                    if let error = paymentError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // Scripture
                    VStack(spacing: 4) {
                        Text("\"Give, and it will be given to you. A good measure, pressed down, shaken together and running over.\"")
                            .font(.caption.italic())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Text("— Luke 6:38")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Give Now")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if stripeService.isProcessing {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Processing your gift...")
                                .font(.headline)
                            Text("\"The Lord loves a cheerful giver\"")
                                .font(.caption.italic())
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .background(.ultraThickMaterial)
                        .cornerRadius(20)
                    }
                }
            }
            .alert("Gift Sent!", isPresented: $showingSuccess) {
                Button("Done") { dismiss() }
            } message: {
                if let result = stripeService.lastPaymentResult {
                    Text("Your \(result.amount.currencyFormatted) gift to \(result.recipientName) has been sent. Thank you for your generosity!")
                }
            }
        }
    }

    private func searchMinistries() {
        guard !searchQuery.isEmpty else { return }
        isSearching = true
        Task {
            do {
                searchResults = try await stripeService.searchConnectedMinistries(query: searchQuery)
            } catch {
                paymentError = error.localizedDescription
            }
            isSearching = false
        }
    }

    private func processApplePayGift() {
        guard let amountDecimal = Decimal(string: amount), amountDecimal > 0 else { return }
        let recipientName = recipient?.name ?? selectedAccount?.name ?? ""
        let accountId = selectedAccount?.stripeAccountId ?? ""

        Task {
            do {
                let intent = try await stripeService.createPaymentIntent(
                    amount: amountDecimal,
                    recipientStripeAccountId: accountId,
                    recipientName: recipientName,
                    category: category,
                    donorEmail: nil
                )
                // In production, present PKPaymentAuthorizationViewController
                // and call confirmWithApplePay with the result
                _ = intent // Payment flow would continue here
                recordGift(amount: amountDecimal, recipientName: recipientName, method: .applePay)
                showingSuccess = true
            } catch {
                paymentError = error.localizedDescription
            }
        }
    }

    private func processCardGift() {
        // In production, present card entry form (Stripe Elements)
        // For now, this is the integration point
        guard let amountDecimal = Decimal(string: amount), amountDecimal > 0 else { return }
        let recipientName = recipient?.name ?? selectedAccount?.name ?? ""
        recordGift(amount: amountDecimal, recipientName: recipientName, method: .online)
    }

    private func recordGift(amount: Decimal, recipientName: String, method: PaymentMethod) {
        let descriptor = FetchDescriptor<UserProfile>()
        guard let profile = (try? modelContext.fetch(descriptor))?.first else { return }

        let record = TitheRecord(
            amount: amount,
            category: category,
            recipient: recipientName,
            note: "Sent via Tithe Steward",
            paymentMethod: method
        )
        record.userProfile = profile
        profile.titheRecords.append(record)
        profile.totalGivenAllTime += amount
        modelContext.insert(record)
        try? modelContext.save()
    }
}

#Preview {
    GiveNowView(recipient: nil)
}
