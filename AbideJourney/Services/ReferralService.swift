import Foundation
import SwiftUI

/// Manages the referral system: generate codes, share links, track referrals.
/// Referral data is stored in UserDefaults/AppStorage for simplicity.
/// Premium credit is applied locally — App Store handles actual subscription.
final class ReferralService {
    static let shared = ReferralService()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let referralCode = "referralCode"
        static let referralCount = "referralCount"
        static let referralCreditsEarned = "referralCreditsEarned"
        static let referralCreditUsed = "referralCreditUsed"
        static let referredBy = "referredBy"
    }

    private init() {}

    // MARK: - Referral Code

    /// Gets or generates the user's unique referral code.
    var myReferralCode: String {
        if let existing = defaults.string(forKey: Keys.referralCode) {
            return existing
        }
        let code = generateCode()
        defaults.set(code, forKey: Keys.referralCode)
        return code
    }

    /// Number of friends who used this user's referral code.
    var referralCount: Int {
        get { defaults.integer(forKey: Keys.referralCount) }
        set { defaults.set(newValue, forKey: Keys.referralCount) }
    }

    /// Total months of premium credit earned from referrals.
    var creditsEarned: Int {
        get { defaults.integer(forKey: Keys.referralCreditsEarned) }
        set { defaults.set(newValue, forKey: Keys.referralCreditsEarned) }
    }

    /// Whether the user has already used a referral credit.
    var creditUsed: Bool {
        get { defaults.bool(forKey: Keys.referralCreditUsed) }
        set { defaults.set(newValue, forKey: Keys.referralCreditUsed) }
    }

    /// The code this user was referred by (if any).
    var referredByCode: String? {
        get { defaults.string(forKey: Keys.referredBy) }
        set { defaults.set(newValue, forKey: Keys.referredBy) }
    }

    // MARK: - Actions

    /// Records a successful referral (friend used code).
    func recordReferral() {
        referralCount += 1
        creditsEarned += 1
    }

    /// Generates a shareable message and link.
    func shareMessage(userName: String) -> String {
        let code = myReferralCode
        return """
        Hey! I've been using Abide Journey — a 40-day devotional app that's been \
        incredible for my faith. Use my code \(code) when you sign up and we'll \
        both get 1 month of Premium free!

        Download: https://apps.apple.com/app/abide-journey/id0000000000
        Referral code: \(code)
        """
    }

    /// Deep link URL for referrals.
    func referralURL() -> URL? {
        URL(string: "abidejourney://referral?code=\(myReferralCode)")
    }

    /// Process an incoming referral code (from deep link or manual entry).
    func applyReferralCode(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty,
              trimmed != myReferralCode,
              referredByCode == nil
        else { return false }

        referredByCode = trimmed
        return true
    }

    // MARK: - Private

    private func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        let code = (0..<6).map { _ in
            chars.randomElement()!
        }
        return "AJ-" + String(code)
    }
}
