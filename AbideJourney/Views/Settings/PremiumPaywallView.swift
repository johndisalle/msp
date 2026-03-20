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
        ("heart.fill", "Kingdom-Funded", "We tithe all of our profits after covering our costs to ministry and missions"),
        ("infinity", "Unlimited Journeys", "Start fresh anytime with new personalized paths"),
        ("speaker.wave.2.fill", "Listen to Devotionals", "Have each day's devotional read aloud to you"),
        ("paintpalette.fill", "Custom Themes", "Anxiety, grief, leadership & more deep-dive journeys"),
        ("person.2.fill", "Accountability", "Connect with trusted friends for mutual encouragement"),
        ("square.and.arrow.up", "Export Journals", "Save your reflections as beautiful PDFs"),
        ("xmark.circle", "Ad-Free", "Distraction-free devotional experience"),
    ]

    // Premium-only journey themes to showcase
    private let premiumThemes: [(icon: String, name: String, description: String)] = [
        ("heart.circle.fill", "Overcoming Anxiety", "40 days of peace when your mind won't stop"),
        ("drop.fill", "Walking Through Grief", "Finding God's comfort in seasons of loss"),
        ("figure.stand", "Leading Like Jesus", "Servant leadership for everyday life"),
        ("arrow.trianglehead.2.clockwise.rotate.90.circle.fill", "Starting Over", "Grace for new beginnings after failure"),
        ("person.2.circle.fill", "Healing Relationships", "Restoring what feels broken"),
        ("flame.fill", "Hearing God's Voice", "Learning to listen when God feels silent"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Hero section - lead with free trial
                    heroSection

                    // Testimonial
                    testimonialCard

                    // Premium journey themes preview
                    themesPreview

                    // Feature list
                    featureList

                    // Plan selection
                    planSelection

                    // Error message
                    if let error = purchaseError ?? storeService.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    // Debug: product load status
                    #if DEBUG
                    Text("Products loaded: \(storeService.products.count) | IDs: \(storeService.products.map(\.id).joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                    #endif

                    // Subscribe button
                    subscribeButton

                    // Price disclaimer
                    let priceText: String = {
                        switch selectedPlan {
                        case .yearly:
                            return storeService.yearlyProduct?.displayPrice ?? "$39.99"
                        case .monthly:
                            return storeService.monthlyProduct?.displayPrice ?? "$4.99"
                        }
                    }()
                    Text("3-day free trial, then \(priceText)/\(selectedPlan == .yearly ? "year" : "month"). Cancel anytime.")
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
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        purchaseError = "Purchase restored but profile could not be updated."
                                    }
                                }
                                dismiss()
                            } else {
                                purchaseError = storeService.errorMessage ?? "No purchases found for this Apple ID."
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
                        do {
                            try modelContext.save()
                        } catch {
                            purchaseError = "Premium status could not be saved. Please restart the app."
                        }
                    }
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
                .padding(.top, 24)
                .accessibilityHidden(true)

            Text("Try Premium Free\nfor 3 Days")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("Go deeper in your walk with Christ.\nCancel anytime — no commitment.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Testimonial

    private var testimonialCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 2) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("5 star rating")

            Text("\"I used to feel like I was just going through the motions. This app taught me how to actually connect with God every single day.\"")
                .font(.subheadline)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Text("— Sarah M., Premium member")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    // MARK: - Premium Themes Preview

    private var themesPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(.purple)
                Text("Unlock Deep-Dive Journeys")
                    .font(.headline)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(premiumThemes, id: \.name) { theme in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: theme.icon)
                                .font(.title2)
                                .foregroundStyle(.accent)

                            Text(theme.name)
                                .font(.subheadline.bold())
                                .lineLimit(2)

                            Text(theme.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .frame(width: 150, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Feature List

    private var featureList: some View {
        VStack(spacing: 14) {
            ForEach(features, id: \.0) { icon, title, description in
                HStack(spacing: 14) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 1) {
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
    }

    // MARK: - Plan Selection

    private var planSelection: some View {
        VStack(spacing: 12) {
            if let yearly = storeService.yearlyProduct {
                PlanButton(
                    title: "Yearly",
                    price: yearly.displayPrice + "/year",
                    badge: "Save 33%",
                    isSelected: selectedPlan == .yearly
                ) {
                    selectedPlan = .yearly
                }
            } else {
                PlanButton(
                    title: "Yearly",
                    price: "$39.99/year",
                    badge: "Save 33%",
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
    }

    // MARK: - Subscribe Button

    private var subscribeButton: some View {
        Button {
            Task { await purchaseSelected() }
        } label: {
            Group {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack(spacing: 2) {
                        Text("Start Your Free Trial")
                            .font(.headline)
                        Text("No charge for 3 days")
                            .font(.caption)
                            .opacity(0.85)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isPurchasing ? Color(.systemGray4) : Color.accentColor)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(isPurchasing)
        .padding(.horizontal)
    }

    private func purchaseSelected() async {
        isPurchasing = true
        purchaseError = nil

        // If products haven't loaded yet, retry before giving up
        if storeService.products.isEmpty {
            await storeService.loadProducts()
        }

        let product: Product?
        switch selectedPlan {
        case .monthly:
            product = storeService.monthlyProduct
        case .yearly:
            product = storeService.yearlyProduct
        }

        guard let product else {
            purchaseError = "Product not available. Please close and reopen this screen, or restart the app."
            isPurchasing = false
            return
        }

        do {
            if let _ = try await storeService.purchase(product) {
                // Purchase successful
                if let profile = profiles.first {
                    profile.isPremium = true
                    do {
                        try modelContext.save()
                    } catch {
                        purchaseError = "Purchase succeeded but profile could not be updated. Please restart the app."
                    }
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
        .accessibilityLabel("\(title) plan, \(price)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    PremiumPaywallView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
