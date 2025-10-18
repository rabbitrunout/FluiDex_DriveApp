import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool  // 👈 добавлено

    var body: some View {
        TabView(selection: $selectedTab) {
            // ⛔ DashboardView больше не нужен
            ServiceLogView()
                .tabItem {
                    Label("Services", systemImage: "wrench.and.screwdriver")
                }
                .tag(0)

            TipsView()
                .tabItem {
                    Label("Tips", systemImage: "lightbulb")
                }
                .tag(1)

            ProfileView(isLoggedIn: $isLoggedIn) // 👈 теперь доступен параметр
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(2)
        }
        .accentColor(Color(hex: "#FFD54F"))
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    MainTabView(selectedTab: .constant(0), isLoggedIn: .constant(true))
}
