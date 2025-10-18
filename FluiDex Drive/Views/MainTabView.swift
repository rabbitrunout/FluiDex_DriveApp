import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool

    var body: some View {
        TabView(selection: $selectedTab) {
            // 🏠 Главная панель
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "speedometer")
                }
                .tag(0)

            // 🧾 Сервисный журнал
            ServiceLogView()
                .tabItem {
                    Label("Services", systemImage: "wrench.and.screwdriver")
                }
                .tag(1)

            // 💡 Советы
            TipsView()
                .tabItem {
                    Label("Tips", systemImage: "lightbulb")
                }
                .tag(2)

            // 👤 Профиль
            ProfileView(isLoggedIn: $isLoggedIn)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(3)
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
