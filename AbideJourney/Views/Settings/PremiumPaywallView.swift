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
        case lifetime

        var productID: String {
            switch self {
            case .monthly: return StoreKitService.monthlyProductID
            case .yearly: return StoreKitService.yearlyProductID
            case .lifetime: return StoreKitService.lifetimeProductID
            }
        }
    }

    private let features = [
        ("heart.fill", "Kingdom-Funded", "We tithe our profits to ministry and missions around the world"),
        ("headphones", "Listen Mode", "Professional AI-narrated devotionals with ambient soundscapes like rain, piano, and worship"),
        ("wand.and.stars", "Custom AI Journeys", "Describe what you're going through and AI builds a personalized 40-day journey"),
        ("paintpalette.fill", "Deep-Dive Themes", "Anxiety, grief, leadership & 10+ premium journey themes"),
        ("person.3.fill", "Community Prayer & Testimony Wall", "Pray with believers worldwide and share how God is working in your life"),
        ("heart.circle.fill", "Couples Journey", "Walk through 40 days together with your partner"),
        ("figure.2.and.child.holdinghands", "Family Journey", "Age-appropriate faith journeys for your whole family"),
        ("calendar.badge.clock", "Seasonal Journeys", "Advent, Lent, Holy Week, and seasonal faith experiences"),
        ("person.2.fill", "Accountability Partners", "Invite friends to encourage each other along the way"),
        ("mic.fill", "Voice Journaling", "Speak your reflections instead of typing them out"),
        ("map.fill", "Faith Map & Year in Review", "Visualize your growth with Faith Wrapped and annual reports"),
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
                        // Hero section
                        heroSection

                        // Premium journey themes preview
                        themesPreview

                        // Feature list
                        featureList

                        // Plan selection
                        planSelection

                        // Error message (only show purchase errors, not internal StoreKit debug info)
                        if let error = purchaseError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding(.horizontal)
                        }

                        // Subscribe button
                        subscribeButton

                        // Free trial details (only show if eligible for introductory offer)
                        if selectedPlan == .yearly, let yearly = storeService.yearlyProduct,
                           let intro = yearly.subscription?.introductoryOffer {
                            VStack(spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: "gift.fill")
                                        .font(.caption)
                                        .foregroundStyle(AJTheme.gold)
                                    Text("\(intro.period.value) \(intro.period.unit == .day ? "days" : "weeks") free, then auto-renews yearly")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text("Cancel anytime during your trial — you won't be charged.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .multilineTextAlignment(.center)
                            }
                        }

                        // Subscription details
                        VStack(spacing: 6) {
                            Text(selectedPlan == .lifetime ? "One-time purchase. No subscription." : "Cancel anytime. Subscription auto-renews.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)

                            HStack(spacing: 4) {
                                if let privacyURL = URL(string: "https://johndisalle.github.io/msp/privacy.html") {
                                    Link("Privacy Policy", destination: privacyURL)
                                }
                                Text("·")
                                    .foregroundStyle(.secondary)
                                if let termsURL = URL(string: "https://johndisalle.github.io/msp/terms.html") {
                                    Link("Terms of Service", destination: termsURL)
                                }
                            }
                            .font(.caption)
                        }

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
                                    Analytics.premiumRestored()
                                    withAnimation(.easeInOut(duration: 0.4)) {
                                        showingCelebration = true
                                    }
                                } else {
                                    purchaseError = storeService.errorMessage ?? "No purchases found for this Apple ID."
                                }
                            }
                        }
                        .font(.caption)

                        // Redeem Offer Code
                        Button("Redeem Offer Code") {
                            Task {
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                                    try? await AppStore.presentOfferCodeRedeemSheet(in: windowScene)
                                }
                            }
                        }
                        .font(.caption)
                        .padding(.bottom, 32)
                    }
                }
                .ajScreenBackground()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                    }
                }
                .task {
                    Analytics.paywallViewed()
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
                .foregroundStyle(AJTheme.gold)
                .padding(.top, 24)
                .accessibilityHidden(true)

            Text("Go Deeper\nwith Premium")
                .font(AJTheme.titleFont)
                .multilineTextAlignment(.center)

            Text("AI-narrated devotionals, custom journeys,\ncommunity prayer, and so much more.")
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Premium Themes Preview

    private var themesPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(AJTheme.accentSecondary)
                Text("Unlock Deep-Dive Journeys")
                    .font(AJTheme.subheadlineFont)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(premiumThemes, id: \.name) { theme in
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: theme.icon)
                                .font(.title2)
                                .foregroundStyle(AJTheme.sage)

                            Text(theme.name)
                                .font(.subheadline.bold())
                                .lineLimit(2)

                            Text(theme.description)
                                .font(.caption)
                                .foregroundStyle(AJTheme.secondaryText)
                                .lineLimit(2)
                        }
                        .frame(width: 150, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AJTheme.cardBackground)
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
                        .foregroundStyle(AJTheme.success)

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
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Plan Selection

    private var planSelection: some View {
        VStack(spacing: 12) {
            if storeService.isLoading {
                ProgressView("Loading plans...")
                    .padding()
            } else if storeService.products.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                    Text("Subscription options couldn't be loaded.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Please check your internet connection and try again.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        storeService.loadAttempts = 0
                        Task { await storeService.loadProducts() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                            Text("Try Again")
                        }
                        .font(.subheadline.bold())
                    }
                    .padding(.top, 4)
                }
                .padding()
            } else {
                if let yearly = storeService.yearlyProduct {
                    let hasIntro = yearly.subscription?.introductoryOffer != nil
                    PlanButton(
                        title: "Yearly",
                        price: yearly.displayPrice + "/year",
                        badge: hasIntro ? "Free Trial" : "Best for Year",
                        subtitle: hasIntro ? "Then \(yearly.displayPrice)/year — Save 33%" : "\(yearly.displayPrice)/year — Save 33%",
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
                        subtitle: nil,
                        isSelected: selectedPlan == .monthly
                    ) {
                        selectedPlan = .monthly
                    }
                }

                if let lifetime = storeService.lifetimeProduct {
                    PlanButton(
                        title: "Lifetime",
                        price: lifetime.displayPrice,
                        badge: "Best Value",
                        subtitle: "Pay once, keep forever",
                        isSelected: selectedPlan == .lifetime
                    ) {
                        selectedPlan = .lifetime
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Subscribe Button

    private var hasProducts: Bool {
        switch selectedPlan {
        case .monthly: return storeService.monthlyProduct != nil
        case .yearly: return storeService.yearlyProduct != nil
        case .lifetime: return storeService.lifetimeProduct != nil
        }
    }

    @ViewBuilder
    private var subscribeButton: some View {
        if storeService.isLoading {
            HStack(spacing: 8) {
                ProgressView()
                Text("Loading subscription options...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else if !hasProducts && !storeService.isLoading {
            EmptyView()
        } else {
            Button {
                Task { await purchaseSelected() }
            } label: {
                Group {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(selectedPlan == .yearly && storeService.yearlyProduct?.subscription?.introductoryOffer != nil ? "Start Free Trial" : selectedPlan == .lifetime ? "Buy Once, Keep Forever" : "Subscribe")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isPurchasing ? AJTheme.sandstone : AJTheme.sage)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isPurchasing)
            .padding(.horizontal)
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
        case .lifetime:
            product = storeService.lifetimeProduct
        }

        guard let product else {
            purchaseError = "Subscription not available right now. Please try again later."
            isPurchasing = false
            return
        }

        do {
            if let _ = try await storeService.purchase(product) {
                if let profile = profiles.first {
                    profile.isPremium = true
                    try modelContext.save()
                }
                isPurchasing = false
                Analytics.premiumPurchased(plan: selectedPlan == .yearly ? "yearly" : selectedPlan == .lifetime ? "lifetime" : "monthly")
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
    var subtitle: String? = nil
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
                                .background(AJTheme.gold)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text(price)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .accent : .secondary)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AJTheme.sage.opacity(0.1) : AJTheme.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AJTheme.sage : .clear, lineWidth: 2)
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
        ("headphones", .purple, "Listen Mode", "AI-narrated devotionals with ambient soundscapes"),
        ("paintpalette.fill", .indigo, "Deep-Dive Journeys", "Anxiety, grief, leadership & 10+ premium themes"),
        ("wand.and.stars", .orange, "Custom AI Journeys", "Describe your situation and AI builds a journey for you"),
        ("person.3.fill", .teal, "Community Prayer & Testimonies", "Pray with believers worldwide and share your faith story"),
        ("heart.circle.fill", .pink, "Couples Journey", "Walk through 40 days of growth with your partner"),
        ("figure.2.and.child.holdinghands", .orange, "Family Journey", "Age-appropriate faith journeys for your whole family"),
        ("calendar.badge.clock", .teal, "Seasonal Journeys", "Advent, Lent, Holy Week, and seasonal experiences"),
        ("person.2.fill", .green, "Accountability Partners", "Invite friends to keep each other encouraged"),
        ("mic.fill", .red, "Voice Journaling", "Speak your reflections instead of typing"),
        ("map.fill", .teal, "Faith Map & Year in Review", "Visualize your growth with Faith Wrapped"),
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
                        .fill(AJTheme.goldLight.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .scaleEffect(appeared ? 1 : 0.3)

                    Image(systemName: "crown.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(AJTheme.gold)
                        .symbolEffect(.bounce, value: appeared)
                }
                .padding(.top, 16)

                VStack(spacing: 8) {
                    Text("Welcome to Premium!")
                        .font(AJTheme.titleFont)
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
                                .foregroundStyle(AJTheme.success)
                                .font(.body)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AJTheme.cardBackground)
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
                    Text("Your premium features are ready — explore them now.")
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
                            .background(AJTheme.sage)
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
