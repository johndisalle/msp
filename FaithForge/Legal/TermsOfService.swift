// TermsOfService.swift
// FaithForge
//
// Terms of Service content and view for in-app display and App Store compliance.

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(TermsOfService.content)
                    .font(.body)
                    .padding()
            }
            .navigationTitle("Terms of Service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

enum TermsOfService {
    static let lastUpdated = "March 20, 2026"

    static let content: String = """
    FAITHFORGE TERMS OF SERVICE
    Last Updated: \(lastUpdated)

    Welcome to FaithForge. By downloading, installing, or using the FaithForge application ("App"), you agree to these Terms of Service ("Terms"). If you do not agree, do not use the App.

    1. ACCEPTANCE OF TERMS

    By using FaithForge, you confirm that you are at least 13 years old (or have parental consent) and agree to be bound by these Terms and our Privacy Policy.

    2. DESCRIPTION OF SERVICE

    FaithForge is a gamified Christian discipleship app that helps users build daily spiritual habits through quests, streaks, community challenges, and progress tracking. The App offers both free and premium subscription tiers.

    3. ACCOUNT REGISTRATION

    3.1 You may sign in using Apple Sign In or use the App as a guest.
    3.2 You are responsible for maintaining the security of your account.
    3.3 You agree to provide accurate information and keep it updated.
    3.4 One account per person. Do not share account credentials.

    4. USER CONDUCT

    You agree NOT to:
    • Use the App for any unlawful purpose
    • Attempt to manipulate XP, streaks, or leaderboard rankings
    • Harass, abuse, or send inappropriate content to other users
    • Attempt to reverse-engineer, decompile, or exploit the App
    • Use automated tools, bots, or scripts to interact with the App
    • Impersonate other users or misrepresent your identity
    • Upload harmful, offensive, or inappropriate content in reflections or profiles

    5. USER CONTENT

    5.1 You retain ownership of content you create (reflections, journal entries).
    5.2 By submitting content, you grant FaithForge a limited license to store and display it within the App for your personal use.
    5.3 We may remove content that violates these Terms or community standards.

    6. PREMIUM SUBSCRIPTIONS

    6.1 Pricing & Billing
    • FaithForge Premium is available as monthly, yearly, or lifetime subscriptions
    • Payment is charged to your Apple ID account at confirmation of purchase
    • Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period

    6.2 Cancellation
    • You can manage and cancel subscriptions in your Apple ID account settings
    • Cancellation takes effect at the end of the current billing period
    • No refunds for partial billing periods (subject to Apple's refund policy)

    6.3 Free Trial
    • If offered, free trials convert to paid subscriptions unless cancelled before the trial ends
    • Trial eligibility is determined by Apple and limited to one per Apple ID

    6.4 Price Changes
    • We may change subscription prices with notice
    • Existing subscribers will be notified before renewal at the new price

    7. INTELLECTUAL PROPERTY

    7.1 FaithForge, its design, features, code, and content are owned by us and protected by copyright, trademark, and other intellectual property laws.
    7.2 Scripture quotations and references are in the public domain or used under fair use for devotional purposes.
    7.3 You may not copy, modify, distribute, or create derivative works from the App.

    8. AI-GENERATED CONTENT

    8.1 Premium users may receive AI-generated quest suggestions powered by Anthropic's Claude API.
    8.2 AI content is provided for spiritual encouragement and is not a substitute for pastoral counsel, professional advice, or direct Scripture study.
    8.3 We do not guarantee the theological accuracy of AI-generated content. Users should verify suggestions against Scripture.

    9. COMMUNITY FEATURES

    9.1 Leaderboards display aggregated, anonymized progress data.
    9.2 Friend connections require mutual consent.
    9.3 Community challenges are collaborative features; participation is voluntary.
    9.4 We reserve the right to moderate and remove users who violate community standards.

    10. DISCLAIMER OF WARRANTIES

    THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR SECURE.

    FAITHFORGE IS A SPIRITUAL HABIT-BUILDING TOOL AND DOES NOT PROVIDE PROFESSIONAL THEOLOGICAL, PSYCHOLOGICAL, OR MEDICAL ADVICE.

    11. LIMITATION OF LIABILITY

    TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES ARISING FROM YOUR USE OF THE APP, INCLUDING BUT NOT LIMITED TO LOSS OF DATA, SPIRITUAL DISTRESS, OR INTERRUPTION OF SERVICE.

    OUR TOTAL LIABILITY SHALL NOT EXCEED THE AMOUNT YOU PAID FOR THE APP IN THE 12 MONTHS PRECEDING THE CLAIM.

    12. INDEMNIFICATION

    You agree to indemnify and hold harmless FaithForge and its team from any claims, damages, or expenses arising from your use of the App or violation of these Terms.

    13. TERMINATION

    13.1 You may stop using the App at any time by deleting it.
    13.2 We may suspend or terminate your account for violation of these Terms.
    13.3 Upon termination, your right to use the App ceases. Data deletion follows our Privacy Policy.

    14. GOVERNING LAW

    These Terms are governed by the laws of the United States. Any disputes shall be resolved through binding arbitration, except where prohibited by law.

    15. CHANGES TO TERMS

    We may update these Terms from time to time. Material changes will be communicated through the App. Continued use after changes constitutes acceptance.

    16. SEVERABILITY

    If any provision of these Terms is found unenforceable, the remaining provisions continue in full force.

    17. CONTACT US

    For questions about these Terms:
    Email: legal@faithforgeapp.com
    """
}
