import SwiftUI
import StoreKit

// MARK: - Theme

enum ClipTheme {
    static let sage = Color(red: 0.43, green: 0.56, blue: 0.52)
    static let sageDark = Color(red: 0.31, green: 0.43, blue: 0.40)
    static let gold = Color(red: 0.89, green: 0.83, blue: 0.66)
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.92)

    static let backgroundGradient = LinearGradient(
        colors: [sage, sageDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Theme Slug Mapping

private let couplesThemeTitleMap: [String: String] = [
    "healingRelationships": "Healing Our Relationship",
    "findingPeace": "Finding Peace Together",
    "knowingGod": "Knowing God as a Couple",
    "spiritualGrowth": "Growing Together in Faith",
    "overcomingAnxiety": "Overcoming Worry Together"
]

private func displayTitle(forSlug slug: String) -> String {
    couplesThemeTitleMap[slug] ?? "A 40-Day Journey Together"
}

// MARK: - Root

struct ClipRootView: View {
    let context: InvocationContext

    var body: some View {
        switch context {
        case .none:
            DefaultClipView()
        case .couplesInvite(let from, let theme):
            CouplesInviteClipView(fromName: from, themeSlug: theme)
        }
    }
}

// MARK: - Couples Invite Flow

struct CouplesInviteClipView: View {
    let fromName: String
    let themeSlug: String

    @State private var showPreview = false

    var body: some View {
        ZStack {
            ClipTheme.backgroundGradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Text("ABIDE JOURNEY")
                        .font(.system(size: 13, weight: .semibold, design: .serif))
                        .tracking(2.5)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 24)

                    ZStack {
                        Circle()
                            .fill(ClipTheme.gold.opacity(0.18))
                            .frame(width: 96, height: 96)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(ClipTheme.gold)
                    }

                    VStack(spacing: 12) {
                        Text("\(fromName) wants to journey with you")
                            .font(.system(size: 18, design: .serif))
                            .italic()
                            .foregroundStyle(.white.opacity(0.9))
                            .multilineTextAlignment(.center)

                        Text(displayTitle(forSlug: themeSlug))
                            .font(.system(size: 26, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)

                        Rectangle()
                            .fill(ClipTheme.gold.opacity(0.7))
                            .frame(width: 48, height: 2)
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 24)

                    Text("A 40-day devotional walk with shared scripture, couples reflection prompts, and a daily rhythm of growing together with God.")
                        .font(.system(size: 15))
                        .foregroundStyle(.white.opacity(0.85))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    VStack(spacing: 12) {
                        Button {
                            showPreview = true
                        } label: {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Try a Free 3-Day Preview")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(ClipTheme.sageDark)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(ClipTheme.gold)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }

                        AppStoreOverlayButton(
                            label: "Get the Full Journey",
                            sublabel: "Free download · Premium options"
                        )
                    }
                    .padding(.horizontal, 24)

                    Text("By continuing, you agree to our Terms and Privacy Policy.")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            PreviewJourneyView(themeSlug: themeSlug, fromName: fromName)
        }
    }
}

// MARK: - 3-Day Preview

struct PreviewJourneyView: View {
    let themeSlug: String
    let fromName: String
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDay: Int = 1

    private var previewDays: [PreviewDay] { PreviewContent.days(for: themeSlug) }

    var body: some View {
        NavigationStack {
            ZStack {
                ClipTheme.backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Day picker
                        HStack(spacing: 8) {
                            ForEach(1...3, id: \.self) { day in
                                Button {
                                    withAnimation { selectedDay = day }
                                } label: {
                                    Text("Day \(day)")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(selectedDay == day ? ClipTheme.sageDark : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(selectedDay == day ? ClipTheme.gold : Color.white.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }

                        let day = previewDays[selectedDay - 1]

                        VStack(alignment: .leading, spacing: 12) {
                            Text(day.scriptureReference)
                                .font(.caption.bold())
                                .foregroundStyle(ClipTheme.gold)
                                .tracking(1.5)

                            Text("\u{201C}\(day.scriptureText)\u{201D}")
                                .font(.system(size: 19, weight: .medium, design: .serif))
                                .italic()
                                .foregroundStyle(.white)
                                .lineSpacing(4)
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 10) {
                            Text(day.devotionalTitle)
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text(day.devotionalText)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .lineSpacing(5)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Reflect Together", systemImage: "bubble.left.and.bubble.right.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(ClipTheme.gold)
                            Text(day.couplesPrompt)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .italic()
                        }
                        .padding(20)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(spacing: 10) {
                            Text("Continue all 40 days with \(fromName)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)

                            AppStoreOverlayButton(
                                label: "Get the Full Journey",
                                sublabel: "Free download · Premium options"
                            )
                        }
                        .padding(.top, 12)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

// MARK: - App Store Overlay Button

struct AppStoreOverlayButton: View {
    let label: String
    let sublabel: String
    @State private var showOverlay = false

    var body: some View {
        Button {
            showOverlay = true
        } label: {
            VStack(spacing: 2) {
                Text(label)
                    .font(.system(size: 17, weight: .semibold))
                Text(sublabel)
                    .font(.caption)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
            )
        }
        .appStoreOverlay(isPresented: $showOverlay) {
            SKOverlay.AppClipConfiguration(position: .bottom)
        }
    }
}

// MARK: - Default (no invocation context)

struct DefaultClipView: View {
    var body: some View {
        ZStack {
            ClipTheme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 20) {
                Text("ABIDE JOURNEY")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .tracking(2.5)
                    .foregroundStyle(.white.opacity(0.7))
                Text("A 40-day devotional journey")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(.white)
                AppStoreOverlayButton(
                    label: "Get the Full App",
                    sublabel: "Free download · Premium options"
                )
                .padding(.horizontal, 32)
                .padding(.top, 24)
            }
            .padding()
        }
    }
}

// MARK: - Preview Content (3 hardcoded days per theme)

struct PreviewDay {
    let scriptureReference: String
    let scriptureText: String
    let devotionalTitle: String
    let devotionalText: String
    let couplesPrompt: String
}

enum PreviewContent {
    static func days(for themeSlug: String) -> [PreviewDay] {
        switch themeSlug {
        case "healingRelationships":
            return healingRelationships
        case "findingPeace":
            return findingPeace
        case "knowingGod":
            return knowingGod
        case "spiritualGrowth":
            return spiritualGrowth
        case "overcomingAnxiety":
            return overcomingAnxiety
        default:
            return knowingGod
        }
    }

    static let knowingGod: [PreviewDay] = [
        PreviewDay(
            scriptureReference: "JEREMIAH 29:13",
            scriptureText: "You will seek me and find me when you seek me with all your heart.",
            devotionalTitle: "The Posture of Seeking",
            devotionalText: "Knowing God begins with desire. Not perfection, not theological mastery — desire. God's promise here is staggering: when you seek with your whole heart, you will find Him. Today, as a couple, you take the first step of intentional seeking together.",
            couplesPrompt: "Share with each other: What does it look like for you, personally, to 'seek God with all your heart' in this season?"
        ),
        PreviewDay(
            scriptureReference: "PSALM 46:10",
            scriptureText: "Be still, and know that I am God.",
            devotionalTitle: "Stillness Together",
            devotionalText: "In a world of noise, stillness is a discipline. Today's invitation isn't to do more — it's to be still. To make space, together, for God to speak. Knowing God isn't always about loud encounters; it's often about quiet presence.",
            couplesPrompt: "Sit in silence together for 2 minutes. Then share: what did you notice when you stopped trying to fill the silence?"
        ),
        PreviewDay(
            scriptureReference: "JOHN 17:3",
            scriptureText: "Now this is eternal life: that they know you, the only true God, and Jesus Christ, whom you have sent.",
            devotionalTitle: "Knowing as Eternal Life",
            devotionalText: "Jesus defined eternal life not as a destination but as a relationship — knowing God. This means the journey you're starting isn't a project to finish; it's a relationship to deepen. Forty days won't make you 'done.' But they can be the beginning of something lasting.",
            couplesPrompt: "Discuss: How would your relationship with each other change if knowing God deeply was the goal of your life together?"
        )
    ]

    static let healingRelationships: [PreviewDay] = [
        PreviewDay(
            scriptureReference: "EPHESIANS 4:32",
            scriptureText: "Be kind and compassionate to one another, forgiving each other, just as in Christ God forgave you.",
            devotionalTitle: "Forgiveness as a Beginning",
            devotionalText: "Healing doesn't start with feelings — it starts with a choice. The choice to extend the kind of forgiveness you've already received from God. Today is not about pretending the wound isn't there. It's about deciding the wound won't have the final word.",
            couplesPrompt: "Without rehashing the past: name one thing you each want to release from the relationship's history, starting today."
        ),
        PreviewDay(
            scriptureReference: "PROVERBS 15:1",
            scriptureText: "A gentle answer turns away wrath, but a harsh word stirs up anger.",
            devotionalTitle: "The Power of Tone",
            devotionalText: "Most relational damage isn't done by what we say — it's done by how we say it. Gentleness doesn't mean weakness; it means strength under control. Today, watch your tone with each other. Notice how it changes the room.",
            couplesPrompt: "Share one moment recently when your tone wounded the other. No defending — just owning. Then ask for forgiveness."
        ),
        PreviewDay(
            scriptureReference: "1 CORINTHIANS 13:4-5",
            scriptureText: "Love is patient, love is kind. It does not envy, it does not boast, it is not proud. It does not dishonor others, it is not self-seeking, it is not easily angered, it keeps no record of wrongs.",
            devotionalTitle: "No Record of Wrongs",
            devotionalText: "The hardest line in this passage is 'keeps no record of wrongs.' Healing requires laying down the spreadsheet you've been keeping. Not because the wrongs didn't happen, but because the spreadsheet is killing the love you both want.",
            couplesPrompt: "Together, name one 'record' you've been keeping. Pray that God would help you tear it up."
        )
    ]

    static let findingPeace: [PreviewDay] = [
        PreviewDay(
            scriptureReference: "JOHN 14:27",
            scriptureText: "Peace I leave with you; my peace I give you. I do not give to you as the world gives. Do not let your hearts be troubled and do not be afraid.",
            devotionalTitle: "A Different Kind of Peace",
            devotionalText: "The world's peace depends on circumstances. Jesus' peace doesn't. He offers peace IN the storm, not peace from the absence of storms. Today, ask not for the storm to end, but for His peace to anchor you in it — together.",
            couplesPrompt: "Share with each other: where in your life right now do you most need His peace, not the world's solution?"
        ),
        PreviewDay(
            scriptureReference: "PHILIPPIANS 4:6-7",
            scriptureText: "Do not be anxious about anything, but in every situation, by prayer and petition, with thanksgiving, present your requests to God.",
            devotionalTitle: "Anxiety Met with Prayer",
            devotionalText: "Paul's prescription for anxiety is shockingly simple: prayer with thanksgiving. Not prayer with complaint, not prayer with bargaining — prayer with gratitude. Try it today. List three things you're grateful for before naming what's worrying you.",
            couplesPrompt: "Take turns. Each share three gratitudes, then one worry. Then pray for each other's worry by name."
        ),
        PreviewDay(
            scriptureReference: "ISAIAH 26:3",
            scriptureText: "You will keep in perfect peace those whose minds are steadfast, because they trust in you.",
            devotionalTitle: "Where Your Mind Lives",
            devotionalText: "Peace follows attention. Whatever your mind is fixed on, that's where peace will or won't grow. A steadfast mind isn't a mind that doesn't drift — it's a mind that keeps returning to God when it does. Today, practice the return.",
            couplesPrompt: "What does each of your minds drift to when not occupied? Be honest. Pray together for steadfastness in those places."
        )
    ]

    static let spiritualGrowth: [PreviewDay] = [
        PreviewDay(
            scriptureReference: "2 PETER 3:18",
            scriptureText: "Grow in the grace and knowledge of our Lord and Savior Jesus Christ.",
            devotionalTitle: "The Direction of Growth",
            devotionalText: "Spiritual growth has two dimensions: grace (experiencing God's favor) and knowledge (understanding His character). Most people pursue one and neglect the other. Both are necessary. Both happen over time. Both are happening right now, today.",
            couplesPrompt: "Where have you grown more in the last year — in grace or in knowledge? What do you each need more of going forward?"
        ),
        PreviewDay(
            scriptureReference: "JAMES 1:2-4",
            scriptureText: "Consider it pure joy, my brothers and sisters, whenever you face trials of many kinds, because you know that the testing of your faith produces perseverance.",
            devotionalTitle: "Growth Through Testing",
            devotionalText: "Nobody asks for trials. But James insists they're the soil where perseverance grows. The question isn't whether you'll face them — it's whether you'll let them make you bitter or mature. Today, name a trial. Then ask: what could maturity look like in this?",
            couplesPrompt: "Share a current trial each of you is facing. How can you encourage each other toward maturity, not bitterness, in it?"
        ),
        PreviewDay(
            scriptureReference: "PHILIPPIANS 1:6",
            scriptureText: "Being confident of this, that he who began a good work in you will carry it on to completion until the day of Christ Jesus.",
            devotionalTitle: "He's Not Done With You",
            devotionalText: "If you've ever felt like a spiritual failure, this verse is for you. God starts what He finishes. Your growth isn't your project — it's His. You're not behind. You're not failing. You're being formed, one day at a time, by the One who keeps His promises.",
            couplesPrompt: "Tell each other one way you've seen God carrying His good work forward in your partner's life — recently."
        )
    ]

    static let overcomingAnxiety: [PreviewDay] = [
        PreviewDay(
            scriptureReference: "1 PETER 5:7",
            scriptureText: "Cast all your anxiety on him because he cares for you.",
            devotionalTitle: "Cast, Don't Carry",
            devotionalText: "Anxiety thrives when we carry what was meant to be cast. Peter's verb here is forceful — throw it, hurl it, get it off you and onto Him. Why? Because He cares. Not because He's obligated. Because He cares for you, by name.",
            couplesPrompt: "Name out loud — to each other and to God — one anxiety you've been carrying. Practice 'casting' it, even if it feels small."
        ),
        PreviewDay(
            scriptureReference: "MATTHEW 6:34",
            scriptureText: "Therefore do not worry about tomorrow, for tomorrow will worry about itself. Each day has enough trouble of its own.",
            devotionalTitle: "Today Is Enough",
            devotionalText: "Most anxiety isn't about today — it's about a tomorrow we're trying to control from here. Jesus' instruction is almost rude in its simplicity: don't. Today has enough. Live in today. Tomorrow will get its own grace when it arrives.",
            couplesPrompt: "What 'tomorrow worry' has been stealing your today? Help each other name one and gently set it down."
        ),
        PreviewDay(
            scriptureReference: "PSALM 94:19",
            scriptureText: "When anxiety was great within me, your consolation brought me joy.",
            devotionalTitle: "Anxiety Met with Consolation",
            devotionalText: "The Psalmist doesn't deny anxiety — he names it and brings it to God. And what he finds isn't a lecture. It's consolation. Joy. The presence of God doesn't always remove the anxiety, but it always meets it. Today, bring yours. See what He brings back.",
            couplesPrompt: "Spend 5 minutes apart, each praying about a personal anxiety. Then come back together and share what God brought to mind."
        )
    ]
}
