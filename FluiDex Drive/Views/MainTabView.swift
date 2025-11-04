import SwiftUI

struct MainTabView: View {
    @Binding var selectedTab: Int
    @Binding var isLoggedIn: Bool

    // 👤 Имя текущего пользователя
    @AppStorage("userName") private var userName: String = "Driver"

    var body: some View {
        ZStack {
            // 🌌 Фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // 🟣 Приветствие
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
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.15), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // 🔹 Контент вкладок
                TabView(selection: $selectedTab) {
                    DashboardView()
                        .tabItem {
                            Label("Dashboard", systemImage: "speedometer")
                        }
                        .tag(0)

                    AddServiceView()
                        .tabItem {
                            Label("Service", systemImage: "wrench.and.screwdriver")
                        }
                        .tag(1)

                    ProfileView(isLoggedIn: $isLoggedIn) // ✅ передали нужный binding
                        .tabItem {
                            Label("Profile", systemImage: "person.crop.circle")
                        }
                        .tag(2)
                }

                .accentColor(Color(hex: "#FFD54F"))
            }
            OBDLiveDataView()
                .tabItem {
                    Label("OBD", systemImage: "antenna.radiowaves.left.and.right")
                }

        }
    }
}

#Preview {
    MainTabView(selectedTab: .constant(0), isLoggedIn: .constant(true))
}
