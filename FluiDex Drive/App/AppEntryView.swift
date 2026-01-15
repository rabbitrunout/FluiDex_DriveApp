import SwiftUI

struct AppEntryView: View {
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("hasSelectedCar") private var hasSelectedCar: Bool = false

    @State private var selectedTab = 0
    @State private var showWelcome = false

    var body: some View {
        ZStack {
            // ✅ Welcome показываем только если пользователь уже залогинен
            if showWelcome && isLoggedIn {
                WelcomeAnimationView(
                    showWelcome: $showWelcome,
                    isLoggedIn: $isLoggedIn,
                    hasSelectedCar: $hasSelectedCar
                )
            } else {
                Group {
                    if !isLoggedIn {
                        // 🔐 Пользователь не вошёл → экран входа
                        ContentView()

                    } else if !hasSelectedCar {
                        // 🚗 Вошёл, но не выбрал машину
                        CarSelectionView(hasSelectedCar: $hasSelectedCar)

                    } else {
                        // 🏠 Всё готово → главный таббар
                        MainTabView(selectedTab: $selectedTab, isLoggedIn: $isLoggedIn)
                    }
                }
            }
        }
        .onAppear {
            // ✅ при запуске приложения
            showWelcome = isLoggedIn
        }
        .onChange(of: scenePhase) { _, phase in
            // ✅ каждый раз когда пользователь открывает приложение (возврат из background)
            if phase == .active {
                showWelcome = isLoggedIn
            }
        }
        .onChange(of: isLoggedIn) { _, newValue in
            if !newValue {
                // 🔄 Когда выходим — сбрасываем состояние
                hasSelectedCar = false
                selectedTab = 0
                showWelcome = false
            }
        }
    }
}

#Preview {
    AppEntryView()
}
