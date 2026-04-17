import SwiftUI
import SwiftData

// MARK: - Breathing Session Model

struct BreathingSession: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let icon: String
    let color: Color
    let inhale: Double
    let hold: Double
    let exhale: Double
    let holdAfterExhale: Double
    let rounds: Int
    let scripture: String
    let reference: String
    let meditation: String
    let isPremium: Bool

    var totalCycleDuration: Double {
        inhale + hold + exhale + holdAfterExhale
    }

    var estimatedMinutes: Int {
        Int(ceil(totalCycleDuration * Double(rounds) / 60.0))
    }
}

// MARK: - Session Library

enum BreathingLibrary {
    static let sessions: [BreathingSession] = [
        BreathingSession(
            name: "Peace of God",
            subtitle: "Calm anxiety with God's peace",
            icon: "wind",
            color: .blue,
            inhale: 4, hold: 4, exhale: 6, holdAfterExhale: 0,
            rounds: 8,
            scripture: "Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.",
            reference: "John 14:27",
            meditation: "As you breathe in, receive God's peace. As you breathe out, release your worries to Him.",
            isPremium: false
        ),
        BreathingSession(
            name: "Be Still",
            subtitle: "Rest in His presence",
            icon: "leaf.fill",
            color: .green,
            inhale: 4, hold: 7, exhale: 8, holdAfterExhale: 0,
            rounds: 6,
            scripture: "Be still, and know that I am God; I will be exalted among the nations, I will be exalted in the earth.",
            reference: "Psalm 46:10",
            meditation: "Inhale: \"Be still.\" Hold: \"And know.\" Exhale: \"That I am God.\"",
            isPremium: false
        ),
        BreathingSession(
            name: "Strength & Courage",
            subtitle: "Find strength in the Lord",
            icon: "bolt.heart.fill",
            color: .orange,
            inhale: 5, hold: 3, exhale: 5, holdAfterExhale: 2,
            rounds: 8,
            scripture: "Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.",
            reference: "Joshua 1:9",
            meditation: "Breathe in His strength. Hold His promise. Breathe out fear and doubt.",
            isPremium: true
        ),
        BreathingSession(
            name: "Trust & Surrender",
            subtitle: "Let go and trust God",
            icon: "hands.sparkles.fill",
            color: .purple,
            inhale: 4, hold: 4, exhale: 4, holdAfterExhale: 4,
            rounds: 7,
            scripture: "Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.",
            reference: "Proverbs 3:5-6",
            meditation: "Inhale trust. Hold surrender. Exhale control. Rest in His plan.",
            isPremium: true
        ),
        BreathingSession(
            name: "Gratitude Breath",
            subtitle: "Breathe in thankfulness",
            icon: "sun.max.fill",
            color: .yellow,
            inhale: 4, hold: 2, exhale: 6, holdAfterExhale: 0,
            rounds: 10,
            scripture: "Give thanks in all circumstances; for this is God's will for you in Christ Jesus.",
            reference: "1 Thessalonians 5:18",
            meditation: "With each breath, thank God for one blessing. Let gratitude fill your lungs and your heart.",
            isPremium: true
        ),
        BreathingSession(
            name: "Evening Rest",
            subtitle: "Prepare for restful sleep",
            icon: "moon.stars.fill",
            color: .indigo,
            inhale: 4, hold: 7, exhale: 8, holdAfterExhale: 0,
            rounds: 6,
            scripture: "In peace I will lie down and sleep, for you alone, Lord, make me dwell in safety.",
            reference: "Psalm 4:8",
            meditation: "Release the day to God. Each exhale carries away worry. Each inhale draws in His rest.",
            isPremium: true
        ),
        BreathingSession(
            name: "Morning Awakening",
            subtitle: "Start your day with God",
            icon: "sunrise.fill",
            color: .pink,
            inhale: 5, hold: 2, exhale: 5, holdAfterExhale: 0,
            rounds: 8,
            scripture: "This is the day that the Lord has made; let us rejoice and be glad in it.",
            reference: "Psalm 118:24",
            meditation: "Breathe in new mercies. Breathe out yesterday's burdens. Today is His gift to you.",
            isPremium: true
        ),
        BreathingSession(
            name: "Forgiveness",
            subtitle: "Release and be set free",
            icon: "heart.circle.fill",
            color: .red,
            inhale: 4, hold: 4, exhale: 8, holdAfterExhale: 0,
            rounds: 7,
            scripture: "Bear with each other and forgive one another if any of you has a grievance against someone. Forgive as the Lord forgave you.",
            reference: "Colossians 3:13",
            meditation: "Breathe in God's forgiveness for you. Hold it in your heart. Breathe out forgiveness to others.",
            isPremium: true
        ),
    ]
}

// MARK: - Main View

struct BreathingMeditationView: View {
    @State private var selectedSession: BreathingSession?
    @State private var showingPremiumPaywall = false
    @Query private var profiles: [UserProfile]

    // FIX: read premium from the same SwiftData source as the rest of
    // the app. The old UserDefaults key "isPremiumUser" was never set,
    // so paying users saw all 6 premium Breathe sessions as locked.
    private var isPremium: Bool {
        profiles.first?.isPremium ?? false
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AJTheme.sage.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "wind")
                            .font(.system(size: 36))
                            .foregroundStyle(AJTheme.sage)
                    }

                    Text("Breathe with Scripture")
                        .font(AJTheme.headlineFont)

                    Text("Guided breathing exercises paired with God's Word\nto calm your mind, body, and spirit.")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.top, 8)

                Text("These exercises are for relaxation and spiritual focus only. They are not a substitute for medical treatment. If you have breathing difficulties or health concerns, consult a healthcare professional.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Session cards
                LazyVStack(spacing: 14) {
                    ForEach(BreathingLibrary.sessions) { session in
                        BreathingSessionCard(session: session, isLocked: session.isPremium && !isPremium) {
                            if session.isPremium && !isPremium {
                                showingPremiumPaywall = true
                            } else {
                                selectedSession = session
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .ajScreenBackground()
        .navigationTitle("Breathe")
        .fullScreenCover(item: $selectedSession) { session in
            BreathingPlayerView(session: session)
        }
        .sheet(isPresented: $showingPremiumPaywall) {
            PremiumPaywallView()
        }
    }
}

// MARK: - Session Card

private struct BreathingSessionCard: View {
    let session: BreathingSession
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(session.color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: session.icon)
                        .font(.title3)
                        .foregroundStyle(session.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.name)
                            .font(.subheadline.bold())
                            .foregroundStyle(AJTheme.primaryText)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(AJTheme.gold)
                        }
                    }
                    Text(session.subtitle)
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("\(session.estimatedMinutes)")
                        .font(.caption.bold())
                        .foregroundStyle(session.color)
                    Text("min")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.secondaryText)
                }

                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isLocked ? .gray : session.color)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AJTheme.cardBackground)
                    .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
            )
            .opacity(isLocked ? 0.7 : 1)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Breathing Player (Full Screen)

struct BreathingPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let session: BreathingSession

    @State private var phase: BreathPhase = .ready
    @State private var currentRound = 0
    @State private var progress: Double = 0
    @State private var circleScale: CGFloat = 0.5
    @State private var phaseTimeRemaining: Double = 0
    @State private var isActive = false
    @State private var showScripture = true
    @State private var isComplete = false

    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    enum BreathPhase {
        case ready
        case inhale
        case holdIn
        case exhale
        case holdOut
        case complete

        var displayText: String {
            switch self {
            case .ready: return "Ready"
            case .inhale: return "Breathe In"
            case .holdIn: return "Hold"
            case .exhale: return "Breathe Out"
            case .holdOut: return "Hold"
            case .complete: return "Complete"
            }
        }
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    session.color.opacity(0.15),
                    Color(.systemBackground),
                    session.color.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if isActive && !isComplete {
                        Text("Round \(currentRound)/\(session.rounds)")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()

                Spacer()

                if isComplete {
                    completionView
                } else if !isActive {
                    readyView
                } else {
                    activeBreathingView
                }

                Spacer()

                // Scripture at bottom
                if !isComplete {
                    VStack(spacing: 6) {
                        Text("\u{201C}\(session.scripture)\u{201D}")
                            .font(.caption.italic())
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                        Text("— \(session.reference)")
                            .font(.caption2.bold())
                            .foregroundStyle(session.color)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                    .opacity(showScripture ? 1 : 0.3)
                }
            }
        }
        .onReceive(timer) { _ in
            guard isActive, !isComplete else { return }
            tick()
        }
    }

    // MARK: - Ready View

    private var readyView: some View {
        VStack(spacing: 32) {
            Text(session.name)
                .font(.title.bold())
                .foregroundStyle(AJTheme.primaryText)

            Text(session.meditation)
                .font(.body)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Breathing pattern info
            HStack(spacing: 20) {
                PatternBadge(label: "In", seconds: session.inhale, color: session.color)
                if session.hold > 0 {
                    PatternBadge(label: "Hold", seconds: session.hold, color: session.color)
                }
                PatternBadge(label: "Out", seconds: session.exhale, color: session.color)
                if session.holdAfterExhale > 0 {
                    PatternBadge(label: "Hold", seconds: session.holdAfterExhale, color: session.color)
                }
            }

            Text("\(session.rounds) rounds · ~\(session.estimatedMinutes) min")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                startSession()
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Begin")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 16)
                .background(session.color)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Active Breathing View

    private var activeBreathingView: some View {
        VStack(spacing: 24) {
            // Phase label
            Text(phase.displayText)
                .font(.title2.bold())
                .foregroundStyle(AJTheme.primaryText)
                .animation(.easeInOut, value: phase)

            // Breathing circle
            ZStack {
                // Outer ring
                Circle()
                    .stroke(session.color.opacity(0.15), lineWidth: 3)
                    .frame(width: 220, height: 220)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(session.color.opacity(0.4), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))

                // Breathing orb
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [session.color.opacity(0.6), session.color.opacity(0.15)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(circleScale)
                    .animation(.easeInOut(duration: phaseDuration), value: circleScale)

                // Timer text
                Text("\(Int(ceil(phaseTimeRemaining)))s")
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(session.color)
            }

            // Meditation text
            Text(session.meditation)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            // Pause button
            Button {
                isActive.toggle()
            } label: {
                Image(systemName: isActive ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(session.color)
            }
        }
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(session.color.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(session.color)
            }

            Text("Well Done")
                .font(.title.bold())
                .foregroundStyle(AJTheme.primaryText)

            Text("You spent \(session.estimatedMinutes) minutes\nbreathing with God.")
                .font(.body)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            VStack(spacing: 6) {
                Text("\u{201C}\(session.scripture)\u{201D}")
                    .font(.body.italic())
                    .foregroundStyle(AJTheme.primaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                Text("— \(session.reference)")
                    .font(.subheadline.bold())
                    .foregroundStyle(session.color)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)

            Button {
                dismiss()
            } label: {
                Text("Amen")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 14)
                    .background(session.color)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Logic

    private var phaseDuration: Double {
        switch phase {
        case .ready: return 0
        case .inhale: return session.inhale
        case .holdIn: return session.hold
        case .exhale: return session.exhale
        case .holdOut: return session.holdAfterExhale
        case .complete: return 0
        }
    }

    private func startSession() {
        currentRound = 1
        isActive = true
        transitionTo(.inhale)
    }

    private func transitionTo(_ newPhase: BreathPhase) {
        phase = newPhase
        phaseTimeRemaining = phaseDuration
        progress = 0

        switch newPhase {
        case .inhale:
            circleScale = 1.0
        case .holdIn:
            circleScale = 1.0
        case .exhale:
            circleScale = 0.5
        case .holdOut:
            circleScale = 0.5
        default:
            break
        }
    }

    private func tick() {
        let dt = 0.05
        phaseTimeRemaining -= dt

        let duration = phaseDuration
        if duration > 0 {
            progress = 1.0 - (phaseTimeRemaining / duration)
        }

        if phaseTimeRemaining <= 0 {
            advancePhase()
        }
    }

    private func advancePhase() {
        switch phase {
        case .inhale:
            if session.hold > 0 {
                transitionTo(.holdIn)
            } else {
                transitionTo(.exhale)
            }
        case .holdIn:
            transitionTo(.exhale)
        case .exhale:
            if session.holdAfterExhale > 0 {
                transitionTo(.holdOut)
            } else {
                finishRound()
            }
        case .holdOut:
            finishRound()
        default:
            break
        }
    }

    private func finishRound() {
        if currentRound >= session.rounds {
            isComplete = true
            phase = .complete
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            currentRound += 1
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            transitionTo(.inhale)
        }
    }
}

// MARK: - Pattern Badge

private struct PatternBadge: View {
    let label: String
    let seconds: Double
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(seconds))s")
                .font(.subheadline.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 50)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        BreathingMeditationView()
    }
}
