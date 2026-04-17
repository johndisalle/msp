import AuthenticationServices
import CryptoKit
import Foundation
import SwiftUI

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    enum AuthMethod: String {
        case apple
        case email
    }

    private(set) var isSignedIn = false
    private(set) var authMethod: AuthMethod?
    private(set) var appleUserID: String?
    private(set) var userEmail: String?
    private(set) var userFullName: String?

    private let userIDKey = "appleUserID"
    private let authMethodKey = "authMethod"
    private let emailKey = "userEmail"
    private let nameKey = "userFullName"
    private let passwordHashKey = "passwordHash"

    private init() {
        if let method = KeychainHelper.load(key: authMethodKey) {
            authMethod = AuthMethod(rawValue: method)
            isSignedIn = true

            if let savedName = KeychainHelper.load(key: nameKey) {
                userFullName = savedName
            }
            if let savedEmail = KeychainHelper.load(key: emailKey) {
                userEmail = savedEmail
            }
            if let savedAppleID = KeychainHelper.load(key: userIDKey) {
                appleUserID = savedAppleID
            }
        }
    }

    // MARK: - Sign in with Apple

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) throws {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                throw AuthError.invalidCredential
            }

            let userID = credential.user
            appleUserID = userID
            authMethod = .apple
            isSignedIn = true

            KeychainHelper.save(key: userIDKey, value: userID)
            KeychainHelper.save(key: authMethodKey, value: AuthMethod.apple.rawValue)

            if let name = credential.fullName {
                let components = [name.givenName, name.familyName].compactMap { $0 }
                if !components.isEmpty {
                    let fullName = components.joined(separator: " ")
                    userFullName = fullName
                    KeychainHelper.save(key: nameKey, value: fullName)
                }
            }
            if let email = credential.email {
                userEmail = email
                KeychainHelper.save(key: emailKey, value: email)
            }

        case .failure(let error):
            throw error
        }
    }

    // MARK: - Email/Password Sign Up

    func signUp(name: String, email: String, password: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw AuthError.emptyName
        }
        guard isValidEmail(trimmedEmail) else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }

        // Check if account already exists
        if KeychainHelper.load(key: "account_\(trimmedEmail)") != nil {
            throw AuthError.accountExists
        }

        // Hash the password and store
        let hash = hashPassword(password)
        KeychainHelper.save(key: "account_\(trimmedEmail)", value: hash)

        // Save session
        userFullName = trimmedName
        userEmail = trimmedEmail
        authMethod = .email
        isSignedIn = true

        KeychainHelper.save(key: authMethodKey, value: AuthMethod.email.rawValue)
        KeychainHelper.save(key: emailKey, value: trimmedEmail)
        KeychainHelper.save(key: nameKey, value: trimmedName)
    }

    // MARK: - Email/Password Sign In

    func signIn(email: String, password: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard let storedHash = KeychainHelper.load(key: "account_\(trimmedEmail)") else {
            throw AuthError.accountNotFound
        }

        let inputHash = hashPassword(password)
        guard inputHash == storedHash else {
            throw AuthError.wrongPassword
        }

        // Restore session
        userEmail = trimmedEmail
        authMethod = .email
        isSignedIn = true

        KeychainHelper.save(key: authMethodKey, value: AuthMethod.email.rawValue)
        KeychainHelper.save(key: emailKey, value: trimmedEmail)

        if let savedName = KeychainHelper.load(key: nameKey) {
            userFullName = savedName
        }
    }

    // MARK: - Check Credential State

    func checkCredentialState() async {
        guard let method = authMethod else {
            isSignedIn = false
            return
        }

        switch method {
        case .apple:
            guard let userID = appleUserID else {
                signOut()
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

        case .email:
            // Email accounts stay signed in locally
            isSignedIn = true
        }
    }

    // MARK: - Sign Out

    func signOut() {
        appleUserID = nil
        userEmail = nil
        userFullName = nil
        authMethod = nil
        isSignedIn = false

        KeychainHelper.delete(key: userIDKey)
        KeychainHelper.delete(key: authMethodKey)
        KeychainHelper.delete(key: emailKey)
        KeychainHelper.delete(key: nameKey)
    }

    // MARK: - Helpers

    private func hashPassword(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
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
        case .invalidCredential:
            return "Could not verify your Apple ID. Please try again."
        case .emptyName:
            return "Please enter your name."
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .accountExists:
            return "An account with this email already exists. Try signing in."
        case .accountNotFound:
            return "No account found with this email."
        case .wrongPassword:
            return "Incorrect password. Please try again."
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
