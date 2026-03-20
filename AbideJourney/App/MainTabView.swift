import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .today

    enum Tab: String, CaseIterable {
        case today = "Today"
        case progress = "Progress"
        case director = "Guide"
        case journal = "Journal"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .today: return "sun.max.fill"
            case .progress: return "chart.bar.fill"
            case .director: return "person.crop.circle.badge.checkmark"
            case .journal: return "book.fill"
            case .settings: return "gearshape.fill"
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

            ProgressDashboardView()
                .tabItem {
                    Label(Tab.progress.rawValue, systemImage: Tab.progress.icon)
                }
                .tag(Tab.progress)

            SpiritualDirectorView()
                .tabItem {
                    Label(Tab.director.rawValue, systemImage: Tab.director.icon)
                }
                .tag(Tab.director)

            JournalListView()
                .tabItem {
                    Label(Tab.journal.rawValue, systemImage: Tab.journal.icon)
                }
                .tag(Tab.journal)

            SettingsView()
                .tabItem {
                    Label(Tab.settings.rawValue, systemImage: Tab.settings.icon)
                }
                .tag(Tab.settings)
        }
        .tint(Color.accentColor)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: UserProfile.self, inMemory: true)
}
