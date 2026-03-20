// PrivacyPolicy.swift
// FaithForge
//
// Privacy Policy content and view for in-app display and App Store compliance.

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(PrivacyPolicy.content)
                    .font(.body)
                    .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

enum PrivacyPolicy {
    static let lastUpdated = "March 20, 2026"

    static let content: String = """
    FAITHFORGE PRIVACY POLICY
    Last Updated: \(lastUpdated)

    FaithForge ("we," "our," or "the App") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, and safeguard your information when you use the FaithForge mobile application.

    1. INFORMATION WE COLLECT

    1.1 Account Information
    When you sign in with Apple, we receive:
    • A unique user identifier (Apple ID relay)
    • Your name (if you choose to share it)
    • Your email address (if you choose to share it, may be a relay address)

    We do not receive or store your Apple ID password.

    1.2 Profile & Progress Data
    • Display name you choose
    • Faith assessment responses (category ratings)
    • Daily goal preferences
    • Quest completion history and XP earned
    • Streak data and badge achievements
    • Leaderboard rankings

    1.3 User-Generated Content
    • Reflection journal entries from quests
    • Friend connections and friend codes

    1.4 Health Data (Optional)
    If you grant permission, we access:
    • Sleep analysis data (hours slept)
    • Mindful session minutes

    This data is read-only, processed on-device, and never uploaded to our servers.

    1.5 AI Quest Generation (Premium Feature)
    When AI quests are enabled:
    • Anonymized faith category ratings and weak areas are sent to Anthropic's Claude API
    • No personally identifiable information (name, email, user ID) is included in AI requests
    • Quest prompts contain only aggregated progress data (level, streak count, category scores)

    1.6 Analytics Data
    We collect anonymized usage analytics including:
    • App opens and session duration
    • Feature usage (quests completed, tabs visited)
    • Subscription events
    • Crash reports

    We use Firebase Analytics for this purpose. No analytics data is linked to your personal identity.

    2. HOW WE USE YOUR INFORMATION

    We use your information to:
    • Provide and maintain the App's features
    • Track your spiritual growth progress
    • Display leaderboards and friend connections
    • Generate personalized AI quests (premium)
    • Send notifications you've opted into
    • Improve the App through anonymized analytics
    • Process subscription payments via Apple

    3. DATA STORAGE & SECURITY

    3.1 Local Storage
    Your primary data (profile, quests, streaks, badges) is stored locally on your device using Apple's SwiftData framework. This data remains on your device and under your control.

    3.2 Cloud Storage
    If you create an account, the following is synced to Google Firebase (Firestore):
    • Profile data (display name, XP, level, streak)
    • Leaderboard rankings
    • Friend connections
    • Community challenge participation

    Firebase data is encrypted in transit (TLS) and at rest (AES-256).

    3.3 API Key Security
    If you enter an API key for AI quests, it is stored securely in your device's Keychain and is never transmitted to our servers.

    4. DATA SHARING

    We do NOT sell your personal data. We share data only with:
    • Apple: For Sign In with Apple authentication and subscription processing
    • Google Firebase: For cloud sync of profile and social features (if you create an account)
    • Anthropic: Anonymized context for AI quest generation (premium feature only)

    5. YOUR RIGHTS & CHOICES

    5.1 Account Deletion
    You can delete your account and all associated data at any time from Settings > Account > Delete Account. This removes all cloud-stored data permanently.

    5.2 Data Export
    You can request a copy of your data by contacting us at privacy@faithforgeapp.com.

    5.3 Notifications
    You can manage notification preferences in Settings > Notifications, or disable them entirely via iOS Settings.

    5.4 HealthKit
    HealthKit access can be revoked at any time in iOS Settings > Privacy > Health.

    5.5 Guest Mode
    You can use the App without creating an account. In guest mode, all data stays on-device only.

    6. CHILDREN'S PRIVACY

    FaithForge is suitable for users of all ages. We do not knowingly collect personal information from children under 13 without parental consent. If you are a parent and believe your child has provided personal information, please contact us.

    7. DATA RETENTION

    • Local data: Retained until you delete the app or clear data
    • Cloud data: Retained while your account is active; deleted within 30 days of account deletion
    • Analytics: Aggregated data retained for up to 24 months; individual events for 14 months

    8. CHANGES TO THIS POLICY

    We may update this Privacy Policy from time to time. We will notify you of material changes through the App or via email. Continued use after changes constitutes acceptance.

    9. CONTACT US

    For privacy questions or data requests:
    Email: privacy@faithforgeapp.com

    10. CALIFORNIA RESIDENTS (CCPA)

    California residents have the right to know what personal information is collected, request deletion, and opt out of sale (we do not sell data). To exercise these rights, contact privacy@faithforgeapp.com.

    11. EUROPEAN RESIDENTS (GDPR)

    If you are in the EEA, our legal basis for processing is:
    • Consent (account creation, HealthKit access, notifications)
    • Legitimate interest (app functionality, analytics)
    • Contract performance (subscription services)

    You have the right to access, rectify, erase, restrict, and port your data. Contact privacy@faithforgeapp.com or your local data protection authority.
    """
}
