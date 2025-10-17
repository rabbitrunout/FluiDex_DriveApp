import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // 🌌 Неоновый фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "speedometer")
                    }
                    .tag(0)

                ServiceLogView()
                    .tabItem {
                        Label("Services", systemImage: "wrench.and.screwdriver")
                    }
                    .tag(1)

                TipsView()
                    .tabItem {
                        Label("Tips", systemImage: "lightbulb")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.crop.circle")
                    }
                    .tag(3)
            }
            .accentColor(Color(hex: "#FFD54F")) // 💛 жёлтый акцент
        }
    }
}

#Preview {
    MainTabView()
}
