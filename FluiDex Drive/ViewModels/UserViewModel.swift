import SwiftUI
import Combine

class UserViewModel: ObservableObject {
    @Published var isLoggedIn: Bool {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn") }
    }
    @Published var hasSelectedCar: Bool {
        didSet { UserDefaults.standard.set(hasSelectedCar, forKey: "hasSelectedCar") }
    }
    @Published var selectedCar: String? {
        didSet { UserDefaults.standard.set(selectedCar, forKey: "selectedCar") }
    }
    
    init() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        self.hasSelectedCar = UserDefaults.standard.bool(forKey: "hasSelectedCar")
        self.selectedCar = UserDefaults.standard.string(forKey: "selectedCar")
    }
    
    // 👇 добавляем методы
    func logIn() {
        isLoggedIn = true
    }
    
    func logOut() {
        isLoggedIn = false
        hasSelectedCar = false
        selectedCar = nil
    }
}
