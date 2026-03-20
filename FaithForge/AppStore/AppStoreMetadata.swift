// AppStoreMetadata.swift
// FaithForge
//
// App Store Connect metadata: description, keywords, subtitle, promotional text.
// Reference file — copy these values into App Store Connect.

// swiftlint:disable line_length

enum AppStoreMetadata {

    // MARK: - Basic Info

    /// App Name (30 characters max)
    static let appName = "FaithForge"

    /// Subtitle (30 characters max)
    static let subtitle = "Daily Discipleship Quests"

    /// Primary Category
    static let primaryCategory = "Lifestyle"

    /// Secondary Category
    static let secondaryCategory = "Education"

    /// Age Rating
    static let ageRating = "4+"

    // MARK: - Promotional Text (170 characters max, can be updated without new build)

    static let promotionalText = """
    Build unshakeable spiritual habits with daily quests, faith rings, streaks, and community challenges. Your discipleship journey starts today!
    """

    // MARK: - Description (4000 characters max)

    static let description = """
    FaithForge is the gamified Christian habit builder that makes daily discipleship engaging, consistent, and community-driven — like Duolingo, but for your faith.

    BUILD DAILY SPIRITUAL HABITS
    Complete personalized quests across four key areas of discipleship:
    • The Word — Bible reading, verse memorization, Scripture reflection
    • Prayer — Morning prayer, gratitude, intercession, quiet listening
    • Mission — Acts of kindness, generosity, sharing your faith
    • Rest in God — Digital sabbath, nature walks, mindful breathing

    TRACK YOUR GROWTH
    • Fill your three Faith Rings daily (Word, Communion, Mission)
    • Build and maintain streaks with consecutive daily completions
    • Earn XP and level up from Novice to Shepherd
    • Unlock achievement badges for milestones
    • View detailed weekly progress charts

    GROW TOGETHER
    • Compete on weekly, monthly, and all-time leaderboards
    • Add friends and encourage each other
    • Join community challenges with shared XP goals
    • Celebrate when your community hits milestones together

    SMART FEATURES
    • Personalized faith assessment identifies your growth areas
    • Choose your daily intensity: Light (10 min), Moderate (20 min), or Devoted (30+ min)
    • Four quest types keep things fresh: Timed activities, check-ins, reflections, and quick logs
    • Daily verse of the day for inspiration
    • Gentle reminders to keep your streak alive

    PREMIUM FEATURES
    Upgrade to FaithForge Premium for:
    • AI-powered quests personalized to your faith journey
    • Advanced statistics and growth insights
    • Custom themes
    • Ad-free experience
    • Unlimited friend connections

    APPLE WATCH & WIDGETS
    • Quick prayer logs from your wrist
    • View streaks and quest progress on your watch
    • Home screen widgets to stay on track

    PRIVACY-FIRST
    • Sign in with Apple for secure, private authentication
    • All data stored locally on your device by default
    • Optional cloud sync for social features
    • No data sold to third parties — ever

    Whether you're just starting your faith journey or deepening a lifelong walk with God, FaithForge gives you the structure, motivation, and community to grow every single day.

    Download FaithForge and forge your faith, one quest at a time.
    """

    // MARK: - Keywords (100 characters max, comma-separated)

    static let keywords = "bible,prayer,christian,devotional,habit,streak,discipleship,faith,spiritual,daily"

    // MARK: - What's New (4000 characters max)

    static let whatsNew = """
    Welcome to FaithForge 1.0!

    • Complete daily quests across 4 spiritual disciplines
    • Track progress with Faith Rings, streaks, and XP
    • Level up from Novice to Shepherd
    • Join community challenges and leaderboards
    • Add friends and grow together
    • Apple Watch app for quick prayer logs
    • Home screen widgets for daily reminders
    • Premium: AI-powered personalized quests

    We'd love your feedback — rate us on the App Store!
    """

    // MARK: - Support URL & Marketing URL

    static let supportURL = "https://faithforgeapp.com/support"
    static let marketingURL = "https://faithforgeapp.com"
    static let privacyPolicyURL = "https://faithforgeapp.com/privacy"

    // MARK: - App Store Screenshots Text Overlays

    /// Suggested text for screenshot marketing images (5.5" and 6.7" required)
    static let screenshotCaptions = [
        "Complete Daily Faith Quests",
        "Fill Your Faith Rings",
        "Track Streaks & Level Up",
        "Compete on Leaderboards",
        "Join Community Challenges",
        "AI-Powered Personalized Quests",
    ]

    // MARK: - App Review Notes

    static let reviewNotes = """
    FaithForge is a gamified Christian discipleship app. To test the full experience:

    1. Launch the app and tap "Get Started"
    2. Sign in with Apple or tap "Continue without Account" for guest mode
    3. Complete the faith assessment (rate each category 1-5)
    4. Choose a daily goal intensity
    5. Complete quests on the Home or Quests tab
    6. View progress on the Progress tab
    7. Check leaderboards and challenges on the Community tab

    Premium features (AI Quests) require a subscription. Demo data is provided for leaderboards and challenges.

    No special credentials needed — guest mode provides full access to core features.
    """
}

// swiftlint:enable line_length
