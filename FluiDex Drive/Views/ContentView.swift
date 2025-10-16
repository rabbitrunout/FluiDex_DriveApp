import SwiftUI
import CoreData

struct ContentView: View {
    @State private var isLoggedIn = false
    @State private var hasSelectedCar = true // 🚗 пока true, чтобы сразу переходить в MainTabView
    @State private var showLogin = false     // 👈 добавили это состояние

    var body: some View {
        NavigationStack {
            if !isLoggedIn {
                WelcomeView(
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar,
                    showLogin: $showLogin   // 👈 передаём третий биндинг
                )
            } else if !hasSelectedCar {
                CarSelectionView(hasSelectedCar: $hasSelectedCar)
            } else {
                MainTabView()
            }
        }
    }
}

#Preview {
    ContentView()
}
