import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseCore
import Foundation
import SwiftUI

/// Single source of truth for user identity.
///
/// Architecture:
/// - Every device gets a Firebase anonymous UID at first launch (`bootstrapAnonymousIfNeeded`).
/// - Sign in with Apple links the anonymous account into a permanent Apple-backed UID
///   in place — same UID, all community content stays attached.
/// - New email/password signups go through Firebase Auth.
/// - Legacy email accounts (SHA256 in Keychain, predates Firebase) keep working via
///   `signInLegacyEmail` until those users are migrated or churn out.
///
/// Network calls use `currentIDToken()` for `Authorization: Bearer <token>` headers.
@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    enum AuthMethod: String {
        case anonymous          // Firebase anonymous (default for every device)
        case apple              // Firebase + Sign in with Apple (linked from anonymous)
        case firebaseEmail      // Firebase email/password
        case legacyEmail        // Pre-Firebase Keychain SHA256 (deprecated path)
    }

    // MARK: - Observable state

    /// True if a Firebase user exists (always true after bootstrap, even when anonymous).
    private(set) var hasFirebaseUser = false

    /// True if the user has a *named* identity (Apple, Firebase email, or legacy email).
    /// False for anonymous-only users.
    private(set) var isSignedIn = false

    private(set) var authMethod: AuthMethod?
    private(set) var uid: String?           // Firebase UID (or legacy_<deviceId> for legacy email)
    private(set) var userEmail: String?
    private(set) var userFullName: String?
    private(set) var appleUserID: String?   // Apple's `sub` — kept for credentialState checks

    /// Admin status derived from Firebase custom claim.
    /// Refreshed in bootstrap() and after each sign-in mutation.
    private(set) var isAdmin = false

    /// Admin-granted premium status, read from Firestore via ensureUserProfile.
    /// ORed with StoreKit status when computing profile.isPremium.
    private(set) var isPremiumFromGrant = false

    // MARK: - Keychain keys (legacy + ancillary)

    private let userIDKey = "appleUserID"
    private let authMethodKey = "authMethod"
    private let emailKey = "userEmail"
    private let nameKey = "userFullName"

    // MARK: - Apple nonce (Firebase requires it)

    private var currentNonce: String?

    private init() {
        // Restore display fields from Keychain. The actual signed-in state is
        // resolved against Firebase / Apple in `bootstrap()`.
        if let savedName = KeychainHelper.load(key: nameKey) { userFullName = savedName }
        if let savedEmail = KeychainHelper.load(key: emailKey) { userEmail = savedEmail }
        if let savedAppleID = KeychainHelper.load(key: userIDKey) { appleUserID = savedAppleID }
        if let savedMethod = KeychainHelper.load(key: authMethodKey),
           let m = AuthMethod(rawValue: savedMethod) {
            authMethod = m
        }
    }

    // MARK: - Bootstrap

    /// Call once at app launch (after `FirebaseApp.configure()`).
    /// Ensures every device has a Firebase user — anonymous if no other identity exists.
    func bootstrap() async {
        // Reflect existing Firebase session if there is one.
        if let user = Auth.auth().currentUser {
            uid = user.uid
            hasFirebaseUser = true
            // If we previously stored a non-anonymous method, keep it; otherwise it's anonymous.
            if user.isAnonymous {
                authMethod = (authMethod == .legacyEmail) ? .legacyEmail : .anonymous
                isSignedIn = (authMethod == .legacyEmail)  // legacy email is still "signed in"
            } else {
                isSignedIn = true
                if user.email != nil && authMethod == nil {
                    authMethod = .firebaseEmail
                }
            }
            await refreshAppleCredentialIfNeeded()
            await refreshAdminClaim()
            await ensureUserProfile()
            return
        }

        // No Firebase user — create an anonymous one.
        do {
            let result = try await Auth.auth().signInAnonymously()
            uid = result.user.uid
            hasFirebaseUser = true
            // Preserve legacy email session if it exists.
            if authMethod == .legacyEmail {
                isSignedIn = true
            } else {
                authMethod = .anonymous
                isSignedIn = false
            }
        } catch {
            #if DEBUG
            print("[AuthService] Anonymous bootstrap failed: \(error.localizedDescription)")
            #endif
            hasFirebaseUser = false
        }
        await refreshAdminClaim()
        await ensureUserProfile()
    }

    // MARK: - Apple Sign-In request prep

    /// Pass to `SignInWithAppleButton(onRequest:)` — sets nonce + scopes.
    /// Required because Firebase needs a SHA256-hashed nonce on the request and
    /// the raw nonce when exchanging the credential.
    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    // MARK: - Apple Sign-In completion

    /// Pass to `SignInWithAppleButton(onCompletion:)`.
    /// If the user is currently anonymous, links the Apple identity onto the existing UID.
    /// Otherwise signs in fresh.
    func handleAuthorization(_ result: Result<ASAuthorization, Error>) async throws {
        switch result {
        case .failure(let error):
            throw error

        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }
            guard let nonce = currentNonce else {
                throw AuthError.invalidCredential
            }
            guard let appleIDTokenData = credential.identityToken,
                  let idTokenString = String(data: appleIDTokenData, encoding: .utf8) else {
                throw AuthError.invalidCredential
            }

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: credential.fullName
            )

            // Link if anonymous, otherwise sign in fresh.
            let authResult: AuthDataResult
            if let user = Auth.auth().currentUser, user.isAnonymous {
                do {
                    authResult = try await user.link(with: firebaseCredential)
                } catch let error as NSError where error.code == AuthErrorCode.credentialAlreadyInUse.rawValue {
                    // This Apple ID already has a Firebase account from another device.
                    // Sign in to that account; the orphaned anonymous content on this device is lost.
                    // Acceptable tradeoff for v1 — see MIGRATION-README for the full discussion.
                    authResult = try await Auth.auth().signIn(with: firebaseCredential)
                }
            } else {
                authResult = try await Auth.auth().signIn(with: firebaseCredential)
            }

            uid = authResult.user.uid
            appleUserID = credential.user
            authMethod = .apple
            isSignedIn = true
            hasFirebaseUser = true

            KeychainHelper.save(key: userIDKey, value: credential.user)
            KeychainHelper.save(key: authMethodKey, value: AuthMethod.apple.rawValue)

            if let name = credential.fullName {
                let parts = [name.givenName, name.familyName].compactMap { $0 }
                if !parts.isEmpty {
                    let full = parts.joined(separator: " ")
                    userFullName = full
                    KeychainHelper.save(key: nameKey, value: full)
                }
            }
            if let email = credential.email {
                userEmail = email
                KeychainHelper.save(key: emailKey, value: email)
            } else if let firebaseEmail = authResult.user.email {
                userEmail = firebaseEmail
                KeychainHelper.save(key: emailKey, value: firebaseEmail)
            }

            currentNonce = nil
            await refreshAdminClaim()
            await ensureUserProfile()
        }
    }

    // MARK: - Firebase Email/Password Sign Up

    /// Creates a Firebase email account. If user is currently anonymous, links it.
    func signUp(name: String, email: String, password: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else { throw AuthError.emptyName }
        guard isValidEmail(trimmedEmail) else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }

        let credential = EmailAuthProvider.credential(withEmail: trimmedEmail, password: password)

        let authResult: AuthDataResult
        do {
            if let user = Auth.auth().currentUser, user.isAnonymous {
                authResult = try await user.link(with: credential)
            } else {
                authResult = try await Auth.auth().createUser(withEmail: trimmedEmail, password: password)
            }
        } catch let error as NSError where error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
            throw AuthError.accountExists
        } catch let error as NSError where error.code == AuthErrorCode.weakPassword.rawValue {
            throw AuthError.weakPassword
        }

        // Set display name in Firebase
        let changeRequest = authResult.user.createProfileChangeRequest()
        changeRequest.displayName = trimmedName
        try? await changeRequest.commitChanges()

        uid = authResult.user.uid
        userEmail = trimmedEmail
        userFullName = trimmedName
        authMethod = .firebaseEmail
        isSignedIn = true
        hasFirebaseUser = true

        KeychainHelper.save(key: authMethodKey, value: AuthMethod.firebaseEmail.rawValue)
        KeychainHelper.save(key: emailKey, value: trimmedEmail)
        KeychainHelper.save(key: nameKey, value: trimmedName)
        await refreshAdminClaim()
        await ensureUserProfile()
    }

    // MARK: - Firebase Email/Password Sign In

    /// Signs in with Firebase email. If a legacy Keychain account exists for the same email,
    /// this does NOT migrate the password — user just signs into Firebase fresh.
    func signIn(email: String, password: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        do {
            let result = try await Auth.auth().signIn(withEmail: trimmedEmail, password: password)
            uid = result.user.uid
            userEmail = trimmedEmail
            userFullName = result.user.displayName ?? userFullName
            authMethod = .firebaseEmail
            isSignedIn = true
            hasFirebaseUser = true

            KeychainHelper.save(key: authMethodKey, value: AuthMethod.firebaseEmail.rawValue)
            KeychainHelper.save(key: emailKey, value: trimmedEmail)
            if let name = result.user.displayName {
                KeychainHelper.save(key: nameKey, value: name)
            }
        } catch let error as NSError where error.code == AuthErrorCode.userNotFound.rawValue {
            // Try legacy Keychain path before giving up
            try signInLegacyEmail(email: trimmedEmail, password: password)
        } catch let error as NSError where error.code == AuthErrorCode.wrongPassword.rawValue
                                       || error.code == AuthErrorCode.invalidCredential.rawValue {
            // Could be legacy account with different hash — try legacy path
            do {
                try signInLegacyEmail(email: trimmedEmail, password: password)
            } catch {
                throw AuthError.wrongPassword
            }
        }
        await refreshAdminClaim()
        await ensureUserProfile()
    }

    /// Legacy Keychain SHA256 sign-in. Kept alive for users who created accounts
    /// before the Firebase migration. Does NOT create a Firebase email user — the
    /// device's anonymous Firebase UID remains the identity for community features.
    func signInLegacyEmail(email: String, password: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let storedHash = KeychainHelper.load(key: "account_\(trimmedEmail)") else {
            throw AuthError.accountNotFound
        }
        let inputHash = hashPassword(password)
        guard inputHash == storedHash else { throw AuthError.wrongPassword }

        userEmail = trimmedEmail
        authMethod = .legacyEmail
        isSignedIn = true

        KeychainHelper.save(key: authMethodKey, value: AuthMethod.legacyEmail.rawValue)
        KeychainHelper.save(key: emailKey, value: trimmedEmail)
        if let savedName = KeychainHelper.load(key: nameKey) { userFullName = savedName }
    }

    // MARK: - ID Token

    /// Returns a fresh Firebase ID token for `Authorization: Bearer <token>` headers.
    /// Returns nil if no Firebase user exists (legacy-only path or bootstrap failed).
    func currentIDToken() async -> String? {
        guard let user = Auth.auth().currentUser else { return nil }
        do {
            return try await user.getIDToken()
        } catch {
            #if DEBUG
            print("[AuthService] getIDToken failed: \(error.localizedDescription)")
            #endif
            return nil
        }
    }

    // MARK: - Sign Out

    /// Signs out of Firebase + clears local Keychain.
    /// Re-bootstraps an anonymous Firebase user so the app stays functional for community features.
    func signOut() {
        try? Auth.auth().signOut()

        appleUserID = nil
        userEmail = nil
        userFullName = nil
        authMethod = nil
        isSignedIn = false
        uid = nil
        hasFirebaseUser = false
        isAdmin = false
        isPremiumFromGrant = false

        KeychainHelper.delete(key: userIDKey)
        KeychainHelper.delete(key: authMethodKey)
        KeychainHelper.delete(key: emailKey)
        KeychainHelper.delete(key: nameKey)

        // Re-bootstrap so community features keep working.
        Task { await bootstrap() }
    }

    // MARK: - User profile sync

    /// Calls the server's ensureUserProfile action, which creates or updates the
    /// user's Firestore profile doc and returns its current state. Populates
    /// isPremiumFromGrant based on the returned premium.granted flag.
    /// Safe to call on every launch — it's idempotent.
    func ensureUserProfile() async {
        guard hasFirebaseUser else {
            isPremiumFromGrant = false
            return
        }
        let payload: [String: Any] = ["action": "ensureUserProfile"]
        guard let url = URL(string: "https://us-central1-abidejourney-81288.cloudfunctions.net/communityHTTP") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await currentIDToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let profile = json["profile"] as? [String: Any] else { return }
            let premium = profile["premium"] as? [String: Any]
            isPremiumFromGrant = (premium?["granted"] as? Bool) == true
        } catch {
            #if DEBUG
            print("[AuthService] ensureUserProfile failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Admin claim

    /// Reads the Firebase custom `admin` claim from the current user's ID token.
    /// Force-refresh by default so claims granted since the last token issue are picked up.
    func refreshAdminClaim(forceRefresh: Bool = true) async {
        guard let user = Auth.auth().currentUser else {
            isAdmin = false
            return
        }
        do {
            let result = try await user.getIDTokenResult(forcingRefresh: forceRefresh)
            isAdmin = (result.claims["admin"] as? Bool) == true
        } catch {
            #if DEBUG
            print("[AuthService] refreshAdminClaim failed: \(error.localizedDescription)")
            #endif
            // Don't flip isAdmin on transient errors — keep last known value.
        }
    }

    // MARK: - Apple credential refresh

    private func refreshAppleCredentialIfNeeded() async {
        guard authMethod == .apple, let userID = appleUserID else { return }
        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            if state == .revoked || state == .notFound {
                signOut()
            }
        } catch {
            // Network error — leave state alone
        }
    }

    // MARK: - Helpers

    private func hashPassword(_ password: String) -> String {
        let digest = SHA256.hash(data: Data(password.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Cryptographically random nonce for Apple Sign-In + Firebase.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            precondition(status == errSecSuccess)
            for random in randoms where remaining > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remaining -= 1
                }
            }
        }
        return result
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case emptyName
    case invalidEmail
    case weakPassword
    case accountExists
    case accountNotFound
    case wrongPassword

    var errorDescription: String? {
        switch self {
        case .invalidCredential:    return "Could not verify your Apple ID. Please try again."
        case .emptyName:            return "Please enter your name."
        case .invalidEmail:         return "Please enter a valid email address."
        case .weakPassword:         return "Password must be at least 6 characters."
        case .accountExists:        return "An account with this email already exists. Try signing in."
        case .accountNotFound:      return "No account found with this email."
        case .wrongPassword:        return "Incorrect password. Please try again."
        }
    }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func save(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.abidejourney.app",
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.abidejourney.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.abidejourney.app",
        ]
        SecItemDelete(query as CFDictionary)
    }
}
