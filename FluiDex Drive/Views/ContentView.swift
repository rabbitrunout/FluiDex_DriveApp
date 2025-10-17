import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var hasSelectedCar = false
    @State private var showLogin = false
    @State private var showRegister = false
    @Namespace private var animation // 👈 для плавных переходов

    var body: some View {
        ZStack {
            if !isLoggedIn {
                WelcomeView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin
                )
                .transition(.opacity.combined(with: .scale))
            } else if !hasSelectedCar {
                CarSelectionView(hasSelectedCar: $hasSelectedCar)
                    .transition(.move(edge: .trailing))
            } else {
                MainTabView()
                    .transition(.opacity)
            }

            // 🌟 Экран логина (анимированное появление)
            if showLogin {
                LoginView(
                    isLoggedIn: $isLoggedIn,
                    showRegister: $showRegister,
                    showLogin: $showLogin
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(1)
                .animation(.easeInOut(duration: 0.5), value: showLogin)
            }

            // 🌟 Экран регистрации (анимированное появление)
            if showRegister {
                RegisterView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(2)
                .animation(.easeInOut(duration: 0.5), value: showRegister)
            }

        }
        .background(Color.black.ignoresSafeArea())
    }
}

#Preview {
    ContentView()
}
