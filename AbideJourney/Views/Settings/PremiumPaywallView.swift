import SwiftUI
import SwiftData
import StoreKit

struct PremiumPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var selectedPlan: PremiumPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseError: String?

    private let storeService = StoreKitService.shared

    enum PremiumPlan {
        case monthly
        case yearly

        var productID: String {
            switch self {
            case .monthly: return StoreKitService.monthlyProductID
            case .yearly: return StoreKitService.yearlyProductID
            }
        }
    }

    private let features = [
        ("infinity", "Unlimited Journeys", "Start fresh anytime with new personalized paths"),
        ("speaker.wave.2.fill", "Voice Devotionals", "Full library of narrated devotionals"),
        ("paintpalette.fill", "Custom Themes", "Anxiety, grief, leadership & more deep-dive journeys"),
        ("person.2.fill", "Accountability", "Connect with trusted friends for mutual encouragement"),
        ("square.and.arrow.up", "Export Journals", "Save your reflections as beautiful PDFs"),
        ("xmark.circle", "Ad-Free", "Distraction-free devotional experience")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.orange)
                            .symbolEffect(.bounce)

                        Text("Abide Premium")
                            .font(.largeTitle.bold())

                        Text("Deepen your journey with full access")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)

                    // Features
                    VStack(spacing: 16) {
                        ForEach(features, id: \.0) { icon, title, description in
                            HStack(spacing: 16) {
                                Image(systemName: icon)
                                    .font(.title3)
                                    .foregroundStyle(.accent)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(title)
                                        .font(.subheadline.bold())
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)

                    // Plan selection
                    VStack(spacing: 12) {
                        if let yearly = storeService.yearlyProduct {
                            PlanButton(
                                title: "Yearly",
                                price: yearly.displayPrice + "/year",
                                badge: "Best Value",
                                isSelected: selectedPlan == .yearly
                            ) {
                                selectedPlan = .yearly
                            }
                        } else {
                            PlanButton(
                                title: "Yearly",
                                price: "$39.99/year",
                                badge: "Best Value",
                                isSelected: selectedPlan == .yearly
                            ) {
                                selectedPlan = .yearly
                            }
                        }

                        if let monthly = storeService.monthlyProduct {
                            PlanButton(
                                title: "Monthly",
                                price: monthly.displayPrice + "/month",
                                badge: nil,
                                isSelected: selectedPlan == .monthly
                            ) {
                                selectedPlan = .monthly
                            }
                        } else {
                            PlanButton(
                                title: "Monthly",
                                price: "$4.99/month",
                                badge: nil,
                                isSelected: selectedPlan == .monthly
                            ) {
                                selectedPlan = .monthly
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let error = purchaseError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Subscribe button
                    Button {
                        Task { await purchaseSelected() }
                    } label: {
                        Group {
                            if isPurchasing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start Free Trial")
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isPurchasing ? Color(.systemGray4) : Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal)

                    let priceText: String = {
                        switch selectedPlan {
                        case .yearly:
                            return storeService.yearlyProduct?.displayPrice ?? "$39.99"
                        case .monthly:
                            return storeService.monthlyProduct?.displayPrice ?? "$4.99"
                        }
                    }()
                    Text("7-day free trial, then \(priceText)/\(selectedPlan == .yearly ? "year" : "month"). Cancel anytime.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            await storeService.restorePurchases()
                            if storeService.isPremium {
                                if let profile = profiles.first {
                                    profile.isPremium = true
                                    try? modelContext.save()
                                }
                                dismiss()
                            }
                        }
                    }
                    .font(.caption)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await storeService.loadProducts()
                await storeService.updatePurchasedProducts()
                if storeService.isPremium {
                    if let profile = profiles.first {
                        profile.isPremium = true
                        try? modelContext.save()
                    }
                }
            }
        }
    }

    private func purchaseSelected() async {
        isPurchasing = true
        purchaseError = nil

        let product: Product?
        switch selectedPlan {
        case .monthly:
            product = storeService.monthlyProduct
        case .yearly:
            product = storeService.yearlyProduct
        }

        guard let product else {
            purchaseError = "Product not available. Please try again."
            isPurchasing = false
            return
        }

        do {
            if let _ = try await storeService.purchase(product) {
                // Purchase successful
                if let profile = profiles.first {
                    profile.isPremium = true
                    try? modelContext.save()
                }
                dismiss()
            }
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }

        isPurchasing = false
    }
}

struct PlanButton: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    Text(price)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PremiumPaywallView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
