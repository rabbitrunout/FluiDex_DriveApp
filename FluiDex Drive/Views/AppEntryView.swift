import SwiftUI

struct AppEntryView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("hasSelectedCar") private var hasSelectedCar: Bool = false

    @State private var selectedTab = 0

    var body: some View {
        Group {
            if isLoggedIn {
                if hasSelectedCar {
                    MainTabView(selectedTab: $selectedTab, isLoggedIn: $isLoggedIn)
                } else {
                    CarSelectionView(hasSelectedCar: $hasSelectedCar)
                }
            } else {
                ContentView()
            }
        }
        // ✅ Новый синтаксис onChange
        .onChange(of: isLoggedIn) { oldValue, newValue in
            if !newValue {
                hasSelectedCar = false
                selectedTab = 0
            }
        }
    }
}

#Preview {
    AppEntryView()
}
