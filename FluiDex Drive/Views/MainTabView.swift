import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "speedometer")
                }
            
            ServiceLogView()
                .tabItem {
                    Label("Service Log", systemImage: "wrench.and.screwdriver")
                }
        }
    }
}

#Preview {
    MainTabView()
}
