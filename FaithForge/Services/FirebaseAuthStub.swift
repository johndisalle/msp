// FirebaseAuthStub.swift
// FaithForge
//
// Stub for Firebase Authentication. Replace with real Firebase SDK when ready.
// To integrate:
//   1. Add FirebaseAuth via SPM (firebase-ios-sdk)
//   2. Add GoogleService-Info.plist to the project
//   3. Call FirebaseApp.configure() in FaithForgeApp.init
//   4. Replace stub methods below with real Firebase Auth calls

import Foundation
import AuthenticationServices
import Observation

@Observable
final class FirebaseAuthStub {
    var isSignedIn: Bool = false
    var userID: String?
    var userEmail: String?
    var displayName: String?

    // MARK: - Apple Sign In

    /// Handle the Apple Sign In credential result.
    /// In production, exchange the Apple ID credential with Firebase:
    ///   let credential = OAuthProvider.appleCredential(...)
    ///   let result = try await Auth.auth().signIn(with: credential)
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            if let appleCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                userID = appleCredential.user
                userEmail = appleCredential.email
                if let fullName = appleCredential.fullName {
                    displayName = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                }
                isSignedIn = true
                print("[FirebaseAuthStub] Signed in as: \(userID ?? "unknown")")
            }
        case .failure(let error):
            print("[FirebaseAuthStub] Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    /// Sign out the current user.
    func signOut() {
        isSignedIn = false
        userID = nil
        userEmail = nil
        displayName = nil
        print("[FirebaseAuthStub] Signed out")
    }

    /// Skip sign-in for anonymous / onboarding-only usage.
    func continueAsGuest() {
        isSignedIn = true
        userID = "guest-\(UUID().uuidString.prefix(8))"
        displayName = "Guest"
        print("[FirebaseAuthStub] Continuing as guest")
    }
}

// MARK: - RevenueCat Stub
//
// To integrate RevenueCat for premium subscriptions:
//   1. Add RevenueCat SDK via SPM (purchases-ios)
//   2. Initialize: Purchases.configure(withAPIKey: "your_key")
//   3. Create an entitlement "premium" in RevenueCat dashboard
//   4. Use the PremiumManager below to check access
//
// Example PremiumManager (uncomment when ready):
//
// import RevenueCat
//
// @Observable
// final class PremiumManager {
//     var isPremium: Bool = false
//
//     func checkEntitlement() async {
//         let customerInfo = try? await Purchases.shared.customerInfo()
//         isPremium = customerInfo?.entitlements["premium"]?.isActive == true
//     }
//
//     func purchase(package: Package) async throws {
//         let result = try await Purchases.shared.purchase(package: package)
//         isPremium = result.customerInfo.entitlements["premium"]?.isActive == true
//     }
//
//     func restorePurchases() async throws {
//         let customerInfo = try await Purchases.shared.restorePurchases()
//         isPremium = customerInfo.entitlements["premium"]?.isActive == true
//     }
// }
