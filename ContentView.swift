import SwiftUI

struct ContentView: View {
    @StateObject var inventoryVM = InventoryViewModel()
    @State private var selectedTab: Tab = .dashboard
    @State private var inventoryStatusFilter: InventoryStatusFilter = .all

    enum Tab {
        case dashboard
        case inventory
        case events
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(selectedTab: $selectedTab, inventoryStatusFilter: $inventoryStatusFilter)
                .tag(Tab.dashboard)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
            CostumeListView(statusFilter: $inventoryStatusFilter)
                .tag(Tab.inventory)
                .tabItem {
                    Label("Inventory", systemImage: "tshirt.fill")
                }
            EventListView()
                .tag(Tab.events)
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
        }
        .tint(tintColor)
        .environmentObject(inventoryVM)
    }

    private var tintColor: Color {
        switch selectedTab {
        case .dashboard: return .green
        case .inventory: return .blue
        case .events: return .red
        }
    }
}
