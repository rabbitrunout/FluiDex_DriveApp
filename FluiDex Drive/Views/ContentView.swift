import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var hasSelectedCar = false
    @State private var showLogin = false
    @State private var showRegister = false
    @Namespace private var animation // 🌈 для плавных переходов

    var body: some View {
        ZStack {
            // 🌌 Общий фон для всех экранов
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 🟣 1. Экран приветствия
            if !isLoggedIn && !showLogin && !showRegister {
                WelcomeView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(0)
            }

            // 🟢 2. Экран входа
            if showLogin {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showRegister: $showRegister,
                    showLogin: $showLogin
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
                .animation(.easeInOut(duration: 0.5), value: showLogin)
            }

            
            // 🟡 3. Экран регистрации
            if showRegister {
                RegisterView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin,
                    showRegister: $showRegister // ✅ добавлено
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(2)
                .animation(.easeInOut(duration: 0.5), value: showRegister)
            }


            // 🔵 4. После входа
            if isLoggedIn {
                if !hasSelectedCar {
                    CarSelectionView(hasSelectedCar: $hasSelectedCar)
                        .transition(.move(edge: .trailing))
                        .zIndex(3)
                } else {
                    MainTabView()
                        .transition(.opacity)
                        .zIndex(4)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
