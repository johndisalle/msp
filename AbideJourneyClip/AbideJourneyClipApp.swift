import SwiftUI

@main
struct AbideJourneyClipApp: App {
    @State private var invocationContext: InvocationContext = .none

    var body: some Scene {
        WindowGroup {
            ClipRootView(context: invocationContext)
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    invocationContext = parseInvocation(activity.webpageURL)
                }
        }
    }

    private func parseInvocation(_ url: URL?) -> InvocationContext {
        guard let url, let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return .none
        }
        let params = Dictionary(uniqueKeysWithValues: (comps.queryItems ?? []).compactMap { item in
            item.value.map { (item.name, $0) }
        })
        let path = comps.path

        if path.hasPrefix("/couple") {
            return .couplesInvite(
                fromName: params["from"] ?? "Someone",
                themeSlug: params["theme"] ?? "knowingGod"
            )
        }
        return .none
    }
}

enum InvocationContext: Equatable {
    case none
    case couplesInvite(fromName: String, themeSlug: String)
}
