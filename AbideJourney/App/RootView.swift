import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenWelcomeGuide") private var hasSeenWelcomeGuide = false
    @Query private var profiles: [UserProfile]
    @State private var showSplash = true
    @State private var showWelcomeGuide = false
    @State private var deepLinkService = DeepLinkService.shared

    var body: some View {
        ZStack {
            if hasCompletedOnboarding && !profiles.isEmpty {
                MainTabView()
                    .sheet(isPresented: $showWelcomeGuide) {
                        WelcomeGuideView {
                            hasSeenWelcomeGuide = true
                            showWelcomeGuide = false
                        }
                    }
                    .sheet(isPresented: $deepLinkService.showCouplesInviteSheet) {
                        if let invite = deepLinkService.pendingCouplesInvite {
                            AcceptCouplesInviteView(invite: invite)
                        }
                    }
                    .sheet(isPresented: $deepLinkService.showGiftClaimSheet) {
                        if let gift = deepLinkService.pendingGiftClaim {
                            ClaimGiftJourneyView(gift: gift)
                        }
                    }
                    .onAppear {
                        if !hasSeenWelcomeGuide {
                            showWelcomeGuide = true
                        }
                    }
            } else {
                OnboardingFlowView()
                    .onAppear {
                        if hasCompletedOnboarding && profiles.isEmpty {
                            hasCompletedOnboarding = false
                        }
                    }
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
        .task {
            await AuthService.shared.checkCredentialState()
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            AJTheme.splashGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.white.opacity(0.9))

                VStack(spacing: 6) {
                    Text("Abide Journey")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Abide in Him.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.5)) {
                opacity = 1
            }
        }
    }
}

// MARK: - Welcome Guide (Feature Tour)

struct WelcomeGuideView: View {
    let onDismiss: () -> Void
    @State private var currentPage = 0

    private let pages: [(icon: String, color: Color, title: String, body: String, features: [(icon: String, color: Color, text: String)])] = [
        (
            icon: "book.closed.fill",
            color: AJTheme.sage,
            title: NSLocalizedString("tour.welcome.title", comment: ""),
            body: NSLocalizedString("tour.welcome.body", comment: ""),
            features: []
        ),
        (
            icon: "sunrise.fill",
            color: AJTheme.gold,
            title: NSLocalizedString("tour.today.title", comment: ""),
            body: NSLocalizedString("tour.today.body", comment: ""),
            features: [
                (icon: "text.book.closed.fill", color: .blue, text: "Scripture with your preferred translation"),
                (icon: "heart.text.square.fill", color: .orange, text: "A devotional written for your situation"),
                (icon: "hands.sparkles.fill", color: .purple, text: "A guided prayer you can pray along with"),
                (icon: "headphones", color: .indigo, text: "Listen Mode — AI-narrated devotionals with soundscapes"),
            ]
        ),
        (
            icon: "safari",
            color: AJTheme.sage,
            title: "Discover",
            body: "Browse journey themes, create custom AI journeys, and explore everything the app has to offer.",
            features: [
                (icon: "map.fill", color: .blue, text: "13+ journey themes from Knowing God to Healing Relationships"),
                (icon: "wand.and.stars", color: .purple, text: "Custom AI Journeys built for your situation"),
                (icon: "heart.circle.fill", color: .pink, text: "Couples and Family journey options"),
                (icon: "gift.fill", color: .orange, text: "Gift a journey to someone you love"),
            ]
        ),
        (
            icon: "sparkles",
            color: AJTheme.gold,
            title: "Sanctuary",
            body: "Your spiritual home base. Pray, breathe, share testimonies, and connect with believers.",
            features: [
                (icon: "hands.sparkles.fill", color: .blue, text: "Prayer Wall — submit requests and pray for others"),
                (icon: "text.quote", color: .orange, text: "Testimony Wall — read and share stories of faith"),
                (icon: "wind", color: .teal, text: "Breathing meditation with Scripture"),
                (icon: "person.3.fill", color: .green, text: "Community — connect with believers worldwide"),
            ]
        ),
        (
            icon: "book.fill",
            color: AJTheme.sage,
            title: "Journal & Growth",
            body: "Reflect on your journey, track your spiritual growth, and celebrate how far you've come.",
            features: [
                (icon: "pencil.line", color: .blue, text: "Write your thoughts and reflections"),
                (icon: "mic.fill", color: .purple, text: "Voice journaling — speak your heart"),
                (icon: "flame.fill", color: .orange, text: "Track your streak, habits, and achievements"),
                (icon: "map.fill", color: .teal, text: "Faith Map — visualize your spiritual growth"),
            ]
        ),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        tourPage(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .animation(.easeInOut, value: currentPage)

                // Bottom button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation { currentPage += 1 }
                    } else {
                        onDismiss()
                    }
                } label: {
                    Text(currentPage < pages.count - 1
                         ? NSLocalizedString("action.next", comment: "")
                         : NSLocalizedString("action.letsBegin", comment: ""))
                }
                .buttonStyle(AJPrimaryButtonStyle())
                .padding(.horizontal, AJTheme.paddingXLarge)
                .padding(.bottom, 16)

                if currentPage < pages.count - 1 {
                    Button {
                        onDismiss()
                    } label: {
                        Text(NSLocalizedString("action.skip", comment: ""))
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .padding(.bottom, AJTheme.paddingLarge)
                }
            }
            .background(AJTheme.background.ignoresSafeArea())
            .interactiveDismissDisabled()
        }
    }

    private func tourPage(page: (icon: String, color: Color, title: String, body: String, features: [(icon: String, color: Color, text: String)])) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 40)

                ZStack {
                    Circle()
                        .fill(page.color.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: page.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(page.color)
                }

                Text(page.title)
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                Text(page.body)
                    .font(AJTheme.bodyFont)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, AJTheme.paddingLarge)

                if !page.features.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        ForEach(Array(page.features.enumerated()), id: \.offset) { _, feature in
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(feature.color.opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: feature.icon)
                                        .font(.body)
                                        .foregroundStyle(feature.color)
                                }
                                Text(feature.text)
                                    .font(.system(.subheadline, design: .serif))
                                    .foregroundColor(AJTheme.primaryText)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                    )
                    .padding(.horizontal, AJTheme.paddingLarge)
                }

                Spacer().frame(height: 60)
            }
        }
    }
}

#Preview {
    RootView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
