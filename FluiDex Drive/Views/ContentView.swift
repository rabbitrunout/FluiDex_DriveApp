import SwiftUI
import CoreData

struct ContentView: View {
    @AppStorage("currentUserName") private var currentUserName: String = ""

    @Environment(\.managedObjectContext) private var viewContext

    @State private var isLoggedIn = false
    @State private var hasSelectedCar = false
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var showWelcomeAnimation = false
    @State private var selectedTab = 0

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
                WelcomeView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin
                )
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
                .environment(\.managedObjectContext, viewContext)
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
                .environment(\.managedObjectContext, viewContext)
                .transition(.move(edge: .trailing))
                .zIndex(2)
            }

            // 🚗 Welcome Animation
            if showWelcomeAnimation {
                // ✅ Стало
                WelcomeAnimationView(
                    showWelcome: $showWelcomeAnimation,
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar
                )
            }

            // 🔵 Основной контент
            if isLoggedIn {
                if !hasSelectedCar {
                    CarSelectionView(hasSelectedCar: $hasSelectedCar)
                        .transition(.move(edge: .trailing))
                        .zIndex(4)
                } else {
                    MainTabView(
                        selectedTab: $selectedTab,
                        isLoggedIn: $isLoggedIn
                    )
                    .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
                    .zIndex(5)
                }
            }
        }
        // 🔁 Новый синтаксис iOS 17
        .onChange(of: isLoggedIn) { oldValue, newValue in
            if newValue == false {
                withAnimation(.easeInOut(duration: 0.5)) {
                    selectedTab = 0
                    showLogin = true
                    showRegister = false
                    hasSelectedCar = false
                    showWelcomeAnimation = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
