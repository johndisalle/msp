import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard = "Dashboard"
        case tithe = "Tithe"
        case budget = "Budget"
        case giving = "Giving"
        case more = "More"

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .tithe: return "heart.circle.fill"
            case .budget: return "chart.pie.fill"
            case .giving: return "gift.fill"
            case .more: return "ellipsis.circle.fill"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label(Tab.dashboard.rawValue, systemImage: Tab.dashboard.icon)
                }
                .tag(Tab.dashboard)

            TitheTrackerView()
                .tabItem {
                    Label(Tab.tithe.rawValue, systemImage: Tab.tithe.icon)
                }
                .tag(Tab.tithe)

            BudgetOverviewView()
                .tabItem {
                    Label(Tab.budget.rawValue, systemImage: Tab.budget.icon)
                }
                .tag(Tab.budget)

            GivingHubView()
                .tabItem {
                    Label(Tab.giving.rawValue, systemImage: Tab.giving.icon)
                }
                .tag(Tab.giving)

            SettingsView()
                .tabItem {
                    Label(Tab.more.rawValue, systemImage: Tab.more.icon)
                }
                .tag(Tab.more)
        }
        .tint(Color("AccentGold"))
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
