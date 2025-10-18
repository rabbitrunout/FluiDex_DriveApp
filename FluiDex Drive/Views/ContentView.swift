import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var hasSelectedCar = false
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var showWelcomeAnimation = false
    @State private var selectedTab = 0 // 👈 добавлено

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 🟣 Welcome экран
            if !isLoggedIn && !showLogin && !showRegister && !showWelcomeAnimation {
                WelcomeView(isLoggedIn: $isLoggedIn, hasSelectedCar: $hasSelectedCar, showLogin: $showLogin)
                    .transition(.opacity)
                    .zIndex(0)
            }

            // 🟢 Login экран
            if showLogin {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showRegister: $showRegister,
                    showLogin: $showLogin
                )
                .transition(.move(edge: .trailing))
                .zIndex(1)
            }

            // 🟡 Register экран
            if showRegister {
                RegisterView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin,
                    showRegister: $showRegister,
                    showWelcomeAnimation: $showWelcomeAnimation
                )
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }

            // 🚗 Welcome Animation
            if showWelcomeAnimation {
                WelcomeAnimationView(
                    userName: "Irina",
                    showWelcome: $showWelcomeAnimation,
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar
                )
                .transition(.opacity)
                .zIndex(3)
            }

            // 🔵 Основной контент
            if isLoggedIn {
                if !hasSelectedCar {
                    CarSelectionView(hasSelectedCar: $hasSelectedCar)
                        .transition(.move(edge: .trailing))
                        .zIndex(4)
                } else {
                    MainTabView(selectedTab: $selectedTab, isLoggedIn: $isLoggedIn) // ✅ вот здесь
                        .transition(.opacity)
                        .zIndex(5)
                }
            }

        }
    }
}

#Preview {
    ContentView()
}
