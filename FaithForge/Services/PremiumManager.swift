// PremiumManager.swift
// FaithForge
//
// Manages premium subscriptions via StoreKit 2 with RevenueCat-ready hooks.
// Uses native StoreKit 2 for MVP; uncomment RevenueCat lines when adding the SDK.
//
// SETUP (RevenueCat):
// 1. Add RevenueCat SDK via SPM: https://github.com/RevenueCat/purchases-ios
// 2. Configure in FaithForgeApp.init(): Purchases.configure(withAPIKey: "your_key")
// 3. Uncomment RevenueCat calls below.

import Foundation
import StoreKit
import Observation

// MARK: - Subscription Tier

enum SubscriptionTier: String, CaseIterable, Identifiable {
    case monthly  = "com.faithforge.premium.monthly"
    case yearly   = "com.faithforge.premium.yearly"
    case lifetime = "com.faithforge.premium.lifetime"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .monthly:  return "Monthly"
        case .yearly:   return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly:  return "Billed monthly"
        case .yearly:   return "Save 50% — best value"
        case .lifetime: return "One-time purchase"
        }
    }

    var icon: String {
        switch self {
        case .monthly:  return "calendar"
        case .yearly:   return "star.fill"
        case .lifetime: return "crown.fill"
        }
    }
}

// MARK: - Premium Feature

enum PremiumFeature: String, CaseIterable, Identifiable {
    case aiQuests         = "AI-Powered Quests"
    case advancedStats    = "Advanced Statistics"
    case customThemes     = "Custom Themes"
    case adFree           = "Ad-Free Experience"
    case unlimitedFriends = "Unlimited Friends"
    case prioritySupport  = "Priority Support"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .aiQuests:         return "sparkles"
        case .advancedStats:    return "chart.xyaxis.line"
        case .customThemes:     return "paintpalette.fill"
        case .adFree:           return "eye.slash.fill"
        case .unlimitedFriends: return "person.3.fill"
        case .prioritySupport:  return "envelope.badge.fill"
        }
    }

    var description: String {
        switch self {
        case .aiQuests:         return "Personalized daily quests crafted by AI based on your faith journey"
        case .advancedStats:    return "Deep insights into your spiritual growth with weekly and monthly reports"
        case .customThemes:     return "Customize colors, fonts, and app appearance"
        case .adFree:           return "Remove all ads for a distraction-free experience"
        case .unlimitedFriends: return "Connect with unlimited friends and accountability partners"
        case .prioritySupport:  return "Get faster responses from our support team"
        }
    }
}

// MARK: - PremiumManager

@Observable
final class PremiumManager {
    static let shared = PremiumManager()

    /// Whether the user has an active premium subscription.
    private(set) var isPremium: Bool = false

    /// The user's current subscription tier (nil if free).
    private(set) var currentTier: SubscriptionTier?

    /// Available StoreKit products.
    private(set) var products: [Product] = []

    /// Loading state for purchases.
    private(set) var isLoading: Bool = false

    /// Error message from most recent operation.
    private(set) var errorMessage: String?

    /// Transaction listener task.
    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await checkEntitlements() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    /// Fetch subscription products from the App Store.
    func loadProducts() async {
        do {
            let productIDs = SubscriptionTier.allCases.map(\.rawValue)
            let storeProducts = try await Product.products(for: Set(productIDs))
            await MainActor.run {
                products = storeProducts.sorted { $0.price < $1.price }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load products: \(error.localizedDescription)"
            }
        }
    }

    /// Get the StoreKit Product for a given tier.
    func product(for tier: SubscriptionTier) -> Product? {
        products.first { $0.id == tier.rawValue }
    }

    // MARK: - Purchase

    /// Purchase a subscription tier.
    func purchase(_ tier: SubscriptionTier) async -> Bool {
        guard let product = product(for: tier) else {
            errorMessage = "Product not available."
            return false
        }

        await MainActor.run { isLoading = true }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await checkEntitlements()

                // RevenueCat: Uncomment when SDK is added
                // try await Purchases.shared.syncPurchases()

                await MainActor.run { isLoading = false }
                return true

            case .userCancelled:
                await MainActor.run { isLoading = false }
                return false

            case .pending:
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Purchase pending approval."
                }
                return false

            @unknown default:
                await MainActor.run { isLoading = false }
                return false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Purchase failed: \(error.localizedDescription)"
            }
            return false
        }
    }

    // MARK: - Restore Purchases

    /// Restore previous purchases.
    func restorePurchases() async {
        await MainActor.run { isLoading = true }

        // RevenueCat: Uncomment when SDK is added
        // do {
        //     let customerInfo = try await Purchases.shared.restorePurchases()
        //     await MainActor.run {
        //         isPremium = customerInfo.entitlements["premium"]?.isActive == true
        //         isLoading = false
        //     }
        //     return
        // } catch {
        //     // Fall through to StoreKit
        // }

        // Native StoreKit 2 restore
        do {
            try await AppStore.sync()
            await checkEntitlements()
        } catch {
            await MainActor.run {
                errorMessage = "Restore failed: \(error.localizedDescription)"
            }
        }

        await MainActor.run { isLoading = false }
    }

    // MARK: - Entitlement Check

    /// Check current entitlements from StoreKit.
    func checkEntitlements() async {
        // RevenueCat: Uncomment when SDK is added
        // do {
        //     let customerInfo = try await Purchases.shared.customerInfo()
        //     await MainActor.run {
        //         isPremium = customerInfo.entitlements["premium"]?.isActive == true
        //         if isPremium {
        //             if let productID = customerInfo.entitlements["premium"]?.productIdentifier {
        //                 currentTier = SubscriptionTier(rawValue: productID)
        //             }
        //         } else {
        //             currentTier = nil
        //         }
        //     }
        //     return
        // } catch { /* fall through to StoreKit */ }

        // Native StoreKit 2
        var hasActive = false
        var activeTier: SubscriptionTier?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if let tier = SubscriptionTier(rawValue: transaction.productID) {
                hasActive = true
                activeTier = tier
            }
        }

        await MainActor.run {
            isPremium = hasActive
            currentTier = activeTier
        }
    }

    /// Whether a specific premium feature is unlocked.
    func isFeatureUnlocked(_ feature: PremiumFeature) -> Bool {
        // All features unlock with any premium tier
        isPremium
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.checkEntitlements()
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}
