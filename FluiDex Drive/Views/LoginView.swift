import SwiftUI
import CoreData

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Log In")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Log In") {
                // тут должна быть проверка данных
                isLoggedIn = true
                hasSelectedCar = false
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    LoginView(isLoggedIn: .constant(false), hasSelectedCar: .constant(false))
}
