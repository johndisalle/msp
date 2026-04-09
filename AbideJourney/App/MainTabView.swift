import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today = "Today"
        case discover = "Discover"
        case sanctuary = "Sanctuary"
        case journal = "Journal"

        var icon: String {
            switch self {
            case .today: return "sunrise.fill"
            case .discover: return "safari"
            case .sanctuary: return "sparkles"
            case .journal: return "book.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DailyExperienceView()
                .tabItem {
                    Label(Tab.today.rawValue, systemImage: Tab.today.icon)
                }
                .tag(Tab.today)

            DiscoverView()
                .tabItem {
                    Label(Tab.discover.rawValue, systemImage: Tab.discover.icon)
                }
                .tag(Tab.discover)

            SanctuaryView()
                .tabItem {
                    Label(Tab.sanctuary.rawValue, systemImage: Tab.sanctuary.icon)
                }
                .tag(Tab.sanctuary)

            JournalListView()
                .tabItem {
                    Label(Tab.journal.rawValue, systemImage: Tab.journal.icon)
                }
                .tag(Tab.journal)
        }
        .tint(AJTheme.sage)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
