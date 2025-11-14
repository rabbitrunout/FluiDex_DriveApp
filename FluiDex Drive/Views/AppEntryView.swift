import SwiftUI

struct AppEntryView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("hasSelectedCar") private var hasSelectedCar: Bool = false

    @State private var selectedTab = 0

    var body: some View {
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
        .onChange(of: isLoggedIn) { old, newValue in
            if !newValue {
                // 🔄 Когда выходим — сбрасываем машину
                hasSelectedCar = false
                selectedTab = 0
            }
        }
    }
}

#Preview {
    AppEntryView()
}
