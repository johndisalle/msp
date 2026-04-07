import SwiftUI

struct ReferralView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var codeCopied = false
    @State private var showShareSheet = false
    @State private var redeemCode = ""
    @State private var showRedeemField = false
    @State private var redeemResult: String?

    private let referralService = ReferralService.shared
    private var userName: String

    init(userName: String = "Friend") {
        self.userName = userName
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AJTheme.sage.opacity(0.15))
                                .frame(width: 100, height: 100)
                            Image(systemName: "gift.fill")
                                .font(.system(size: 44))
                                .foregroundStyle(AJTheme.sage)
                        }
                        .padding(.top, 16)

                        Text("Invite Friends,\nGet Premium Free")
                            .font(AJTheme.titleFont)
                            .multilineTextAlignment(.center)

                        Text("Share your code with a friend. When they join,\nyou both get 1 month of Premium free.")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }

                    // Referral Code Card
                    VStack(spacing: 16) {
                        Text("Your Referral Code")
                            .font(AJTheme.captionFont)
                            .foregroundStyle(AJTheme.secondaryText)

                        Text(referralService.myReferralCode)
                            .font(.system(.title, design: .monospaced, weight: .bold))
                            .foregroundStyle(AJTheme.primaryText)
                            .kerning(3)

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = referralService.myReferralCode
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                withAnimation { codeCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation { codeCopied = false }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: codeCopied ? "checkmark" : "doc.on.doc")
                                        .font(.caption)
                                    Text(codeCopied ? "Copied!" : "Copy Code")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AJTheme.sage.opacity(0.1))
                                .foregroundStyle(AJTheme.sage)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                showShareSheet = true
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.caption)
                                    Text("Share")
                                        .font(.subheadline.bold())
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(AJTheme.sage)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                            .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                    )
                    .padding(.horizontal)

                    // Stats
                    HStack(spacing: 0) {
                        StatBox(value: "\(referralService.referralCount)", label: "Friends\nReferred")
                        Divider().frame(height: 50)
                        StatBox(value: "\(referralService.creditsEarned)", label: "Months\nEarned")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                            .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                    )
                    .padding(.horizontal)

                    // How it works
                    VStack(alignment: .leading, spacing: 16) {
                        Text("How It Works")
                            .font(AJTheme.subheadlineFont)

                        StepRow(number: 1, icon: "square.and.arrow.up", text: "Share your unique referral code with friends")
                        StepRow(number: 2, icon: "person.badge.plus", text: "Your friend downloads Abide Journey and enters your code")
                        StepRow(number: 3, icon: "gift.fill", text: "You both get 1 month of Premium — free!")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                            .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                    )
                    .padding(.horizontal)

                    // Redeem code section
                    VStack(spacing: 12) {
                        Button {
                            withAnimation { showRedeemField.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "ticket")
                                Text("Have a referral code?")
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: showRedeemField ? "chevron.up" : "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundStyle(AJTheme.sage)
                        }

                        if showRedeemField {
                            HStack(spacing: 8) {
                                TextField("Enter code", text: $redeemCode)
                                    .textFieldStyle(.roundedBorder)
                                    .textInputAutocapitalization(.characters)
                                    .font(.system(.body, design: .monospaced))

                                Button("Redeem") {
                                    let success = referralService.applyReferralCode(redeemCode)
                                    redeemResult = success
                                        ? "Code applied! You'll receive your free month of Premium."
                                        : "Invalid code. Please check and try again."
                                    UIImpactFeedbackGenerator(style: success ? .medium : .rigid).impactOccurred()
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(AJTheme.sage)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .disabled(redeemCode.trimmingCharacters(in: .whitespaces).isEmpty)
                            }

                            if let result = redeemResult {
                                Text(result)
                                    .font(.caption)
                                    .foregroundStyle(result.contains("applied") ? AJTheme.success : AJTheme.destructive)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                            .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .ajScreenBackground()
            .navigationTitle("Refer a Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [referralService.shareMessage(userName: userName)])
            }
        }
    }
}

// MARK: - Supporting Views

private struct StatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title, design: .serif, weight: .bold))
                .foregroundStyle(AJTheme.sage)
            Text(label)
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct StepRow: View {
    let number: Int
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AJTheme.sage.opacity(0.12))
                    .frame(width: 36, height: 36)
                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AJTheme.sage)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(AJTheme.primaryText)

            Spacer()
        }
    }
}

#Preview {
    ReferralView(userName: "John")
}
