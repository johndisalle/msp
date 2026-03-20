// PremiumPaywallView.swift
// FaithForge
//
// Premium subscription paywall with tier selection, feature list, and purchase flow.

import SwiftUI
import StoreKit

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTier: SubscriptionTier = .yearly
    @State private var showingSuccess = false
    @State private var showingError = false

    private let premium = PremiumManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Tier Selection
                    tierSelectionSection

                    // Purchase Button
                    purchaseButton

                    // Restore + Terms
                    footerSection
                }
                .padding()
            }
            .background(Color("BackgroundPrimary"))
            .navigationTitle("FaithForge Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Welcome to Premium!", isPresented: $showingSuccess) {
                Button("Let's Go!") { dismiss() }
            } message: {
                Text("You now have access to all premium features. God bless your journey!")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(premium.errorMessage ?? "Something went wrong.")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 52))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("FaithGold"), Color("FaithGold").opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("Unlock Your Full Potential")
                .font(.title2.bold())
                .foregroundStyle(Color("TextPrimary"))

            Text("Supercharge your faith journey with AI-powered quests, advanced insights, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.top, 8)
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(PremiumFeature.allCases) { feature in
                HStack(spacing: 14) {
                    Image(systemName: feature.icon)
                        .font(.title3)
                        .foregroundStyle(Color("FaithGold"))
                        .frame(width: 30)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.rawValue)
                            .font(.subheadline.bold())
                            .foregroundStyle(Color("TextPrimary"))

                        Text(feature.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color("BackgroundSecondary"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Tier Selection

    private var tierSelectionSection: some View {
        VStack(spacing: 12) {
            ForEach(SubscriptionTier.allCases) { tier in
                tierCard(tier)
            }
        }
    }

    private func tierCard(_ tier: SubscriptionTier) -> some View {
        let isSelected = selectedTier == tier
        let product = premium.product(for: tier)

        return Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedTier = tier
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("FaithGold") : .secondary)

                Image(systemName: tier.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("FaithGold") : .secondary)
                    .frame(width: 26)

                VStack(alignment: .leading, spacing: 2) {
                    Text(tier.displayName)
                        .font(.headline)
                        .foregroundStyle(Color("TextPrimary"))
                    Text(tier.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if let product {
                    Text(product.displayPrice)
                        .font(.headline)
                        .foregroundStyle(isSelected ? Color("FaithGold") : Color("TextPrimary"))
                } else {
                    Text(tier == .monthly ? "$4.99/mo" : tier == .yearly ? "$29.99/yr" : "$79.99")
                        .font(.headline)
                        .foregroundStyle(isSelected ? Color("FaithGold") : Color("TextPrimary"))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color("FaithGold").opacity(0.1) : Color("BackgroundSecondary"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color("FaithGold") : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                let success = await premium.purchase(selectedTier)
                if success {
                    showingSuccess = true
                } else if premium.errorMessage != nil {
                    showingError = true
                }
            }
        } label: {
            Group {
                if premium.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Subscribe Now")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color("FaithGold"), Color("FaithGold").opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(premium.isLoading)
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 10) {
            Button("Restore Purchases") {
                Task {
                    await premium.restorePurchases()
                }
            }
            .font(.subheadline)
            .foregroundStyle(Color("FaithBlue"))

            Text("Payment will be charged to your Apple ID account. Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
}
