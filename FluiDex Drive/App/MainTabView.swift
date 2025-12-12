import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool
    @StateObject private var tabBar = TabBarVisibility()

    @AppStorage("userName") private var userName: String = "Driver"

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {

                // верхняя плашка приветствия можно оставить / убрать по желанию
                if tabBar.isVisible {
                    VStack(spacing: 6) {
                        Text("👋 Hi, \(userName)")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .shadow(color: .yellow.opacity(0.7), radius: 10, y: 4)

                        Text("Welcome back to your dashboard")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                            .shadow(color: .cyan.opacity(0.6), radius: 8)
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 25)
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [Color.cyan.opacity(0.15), .clear],
                                       startPoint: .top,
                                       endPoint: .bottom)
                    )
                }

                TabView(selection: $selectedTab) {
                    // 0 — Dashboard
                    NavigationStack {
                        DashboardView()
                    }
                    .tabItem {
                        Label("Dashboard", systemImage: "speedometer")
                    }
                    .tag(0)

                    // 1 — Service
                    NavigationStack {
                        AddServiceView()
                    }
                    .tabItem {
                        Label("Service", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(1)

                    // 2 — OBD
                    NavigationStack {
                        OBDLiveDataView()
                    }
                    .tabItem {
                        Label("OBD", systemImage: "antenna.radiowaves.left.and.right")
                    }
                    .tag(2)

                    // 3 — новая вкладка AI & Alerts
                    NavigationStack {
                        AIAlertsView()
                    }
                    .tabItem {
                        Label("AI & Alerts", systemImage: "sparkles")
                    }
                    .tag(3)
                }
                .accentColor(Color(hex: "#FFD54F"))
            }
        }
        .environmentObject(tabBar)
    }
}


#Preview {
    MainTabView(selectedTab: .constant(0), isLoggedIn: .constant(true))
}
