import AuthenticationServices
import Foundation
import SwiftUI

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var isSignedIn = false
    private(set) var appleUserID: String?
    private(set) var userEmail: String?
    private(set) var userFullName: String?

    private let userIDKey = "appleUserID"

    private init() {
        // Load saved Apple user ID from Keychain
        if let savedID = KeychainHelper.load(key: userIDKey) {
            appleUserID = savedID
            isSignedIn = true
        }
    }

    // MARK: - Handle Sign in with Apple Result

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) throws {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }

            let userID = credential.user
            appleUserID = userID
            isSignedIn = true
            KeychainHelper.save(key: userIDKey, value: userID)

            // Apple only provides name/email on FIRST sign-in
            if let name = credential.fullName {
                let components = [name.givenName, name.familyName].compactMap { $0 }
                if !components.isEmpty {
                    userFullName = components.joined(separator: " ")
                }
            }
            if let email = credential.email {
                userEmail = email
            }

        case .failure(let error):
            throw error
        }
    }

    // MARK: - Check Credential State

    func checkCredentialState() async {
        guard let userID = appleUserID else {
            isSignedIn = false
            return
        }

        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            switch state {
            case .authorized:
                isSignedIn = true
            case .revoked, .notFound:
                signOut()
            default:
                break
            }
        } catch {
            // Network error — keep current state
        }
    }

    // MARK: - Sign Out

    func signOut() {
        appleUserID = nil
        userEmail = nil
        userFullName = nil
        isSignedIn = false
        KeychainHelper.delete(key: userIDKey)
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Could not verify your Apple ID. Please try again."
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
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.abidejourney"
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        var newItem = query
        newItem[kSecValueData as String] = data
        SecItemAdd(newItem as CFDictionary, nil)
    }

    static func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.abidejourney",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
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
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "com.abidejourney"
        ]
        SecItemDelete(query as CFDictionary)
    }
}
