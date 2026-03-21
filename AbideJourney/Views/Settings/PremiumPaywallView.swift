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
    @State private var showingCelebration = false

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
        ("heart.fill", "Kingdom-Funded", "We tithe our profits to ministry and missions around the world"),
        ("person.crop.circle.badge.checkmark", "AI Spiritual Guide", "A wise, always-available conversation partner for your faith"),
        ("wand.and.stars", "Custom Journeys", "Describe what you're going through and we'll build a journey for it"),
        ("paintpalette.fill", "Deep-Dive Themes", "Anxiety, grief, leadership & 10+ premium journey themes"),
        ("heart.circle.fill", "Couples Journey", "Walk through 40 days together with your partner"),
        ("person.2.fill", "Accountability Partners", "Invite friends to encourage each other along the way"),
        ("mic.fill", "Voice Journaling", "Speak your reflections instead of typing them out"),
        ("map.fill", "Faith Map & Reports", "Visualize your growth and get an annual faith report"),
        ("gift.fill", "Gift a Journey", "Share a premium journey with someone you love"),
        ("square.and.arrow.up", "Export Journals", "Save your reflections as beautiful PDFs"),
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
            if showingCelebration {
                PremiumCelebrationView(dismiss: dismiss)
            } else {
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
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        showingCelebration = true
                                    }
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
                isPurchasing = false
                withAnimation(.easeInOut(duration: 0.4)) {
                    showingCelebration = true
                }
                return
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

// MARK: - Premium Celebration View

struct PremiumCelebrationView: View {
    let dismiss: DismissAction
    @State private var appeared = false
    @State private var showFeatures = false

    private let unlockedFeatures: [(icon: String, color: Color, title: String, description: String)] = [
        ("person.crop.circle.badge.checkmark", .blue, "AI Spiritual Guide", "Get personal guidance for your walk with God"),
        ("paintpalette.fill", .purple, "Deep-Dive Journeys", "Anxiety, grief, leadership & 10+ premium themes"),
        ("wand.and.stars", .orange, "Custom Journeys", "Describe your situation and get a journey built for you"),
        ("heart.circle.fill", .pink, "Couples Journey", "Walk through 40 days of growth with your partner"),
        ("person.2.fill", .green, "Accountability Partners", "Invite friends to keep each other encouraged"),
        ("mic.fill", .red, "Voice Journaling", "Speak your reflections instead of typing"),
        ("map.fill", .teal, "Faith Map", "Visualize your spiritual growth over time"),
        ("sparkles.rectangle.stack.fill", .indigo, "Annual Faith Report", "A beautiful summary of your year with God"),
        ("gift.fill", .orange, "Gift a Journey", "Share a premium journey with someone you love"),
        ("square.and.arrow.up", .blue, "Export Journals", "Save your reflections as beautiful PDFs"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Crown icon with celebration
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appeared ? 1 : 0.3)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(.orange)
                        .symbolEffect(.bounce, value: appeared)
                }
                .padding(.top, 16)

                VStack(spacing: 8) {
                    Text("Welcome to Premium!")
                        .font(.largeTitle.bold())
                        .opacity(appeared ? 1 : 0)

                    Text("Here's everything you just unlocked:")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .opacity(appeared ? 1 : 0)
                }

                // Feature cards
                VStack(spacing: 12) {
                    ForEach(Array(unlockedFeatures.enumerated()), id: \.offset) { index, feature in
                        HStack(spacing: 14) {
                            Image(systemName: feature.icon)
                                .font(.title3)
                                .foregroundStyle(feature.color)
                                .frame(width: 32)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(feature.title)
                                    .font(.subheadline.bold())
                                Text(feature.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.body)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                        .opacity(showFeatures ? 1 : 0)
                        .offset(y: showFeatures ? 0 : 10)
                        .animation(
                            .easeOut(duration: 0.35).delay(Double(index) * 0.06),
                            value: showFeatures
                        )
                    }
                }
                .padding(.horizontal)

                // CTA
                VStack(spacing: 12) {
                    Text("Try the AI Guide tab — it's ready for you now.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(showFeatures ? 1 : 0)

                    Button {
                        dismiss()
                    } label: {
                        Text("Start Exploring")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal, 32)
                    .opacity(showFeatures ? 1 : 0)
                }
                .padding(.bottom, 40)
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.4)) {
                showFeatures = true
            }
        }
    }
}

#Preview {
    PremiumPaywallView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
