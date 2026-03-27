import Foundation
import SwiftUI

/// Handles URL scheme and universal link deep links for the app.
/// Supports couples journey invitations and gift journey claims.
///
/// URL Scheme: `abidejourney://`
/// - `abidejourney://couple?theme=healingRelationships&from=John`
/// - `abidejourney://gift?theme=overcomingAnxiety&from=Sarah&message=Praying+for+you`
@Observable
final class DeepLinkService {
    static let shared = DeepLinkService()

    // Pending deep link actions (consumed by views)
    var pendingCouplesInvite: CouplesInvite?
    var pendingGiftClaim: GiftClaim?
    var showCouplesInviteSheet = false
    var showGiftClaimSheet = false

    struct CouplesInvite {
        let theme: JourneyTheme
        let fromName: String
    }

    struct GiftClaim {
        let theme: JourneyTheme
        let fromName: String
        let message: String?
    }

    /// The custom URL scheme for the app
    static let urlScheme = "abidejourney"

    // MARK: - Generate Shareable Links

    /// Creates a couples invitation URL that can be shared via messages/email.
    static func couplesInviteURL(theme: JourneyTheme, fromName: String) -> URL {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = "couple"
        components.queryItems = [
            URLQueryItem(name: "theme", value: theme.rawValue),
            URLQueryItem(name: "from", value: fromName),
        ]
        return components.url ?? URL(string: "\(urlScheme)://couple")!
    }

    /// Creates a gift journey URL.
    static func giftURL(theme: JourneyTheme, fromName: String, message: String?) -> URL {
        var components = URLComponents()
        components.scheme = urlScheme
        components.host = "gift"
        var items = [
            URLQueryItem(name: "theme", value: theme.rawValue),
            URLQueryItem(name: "from", value: fromName),
        ]
        if let message, !message.isEmpty {
            items.append(URLQueryItem(name: "message", value: message))
        }
        components.queryItems = items
        return components.url ?? URL(string: "\(urlScheme)://gift")!
    }

    // MARK: - Handle Incoming Links

    /// Processes an incoming URL (from .onOpenURL or scene delegate).
    func handleURL(_ url: URL) {
        // Support both custom scheme and universal links
        let host: String?
        let path: String
        let queryItems: [URLQueryItem]

        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            if url.scheme == Self.urlScheme {
                host = components.host
                path = ""
            } else {
                host = nil
                path = components.path
            }
            queryItems = components.queryItems ?? []
        } else {
            return
        }

        let route = host ?? path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let params = Dictionary(uniqueKeysWithValues: queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })

        switch route {
        case "couple":
            handleCouplesInvite(params: params)
        case "gift":
            handleGiftClaim(params: params)
        default:
            break
        }
    }

    private func handleCouplesInvite(params: [String: String]) {
        guard let themeName = params["theme"],
              let theme = JourneyTheme(rawValue: themeName),
              let fromName = params["from"] else { return }

        pendingCouplesInvite = CouplesInvite(theme: theme, fromName: fromName)
        showCouplesInviteSheet = true
    }

    private func handleGiftClaim(params: [String: String]) {
        guard let themeName = params["theme"],
              let theme = JourneyTheme(rawValue: themeName),
              let fromName = params["from"] else { return }

        pendingGiftClaim = GiftClaim(
            theme: theme,
            fromName: fromName,
            message: params["message"]
        )
        showGiftClaimSheet = true
    }
}
