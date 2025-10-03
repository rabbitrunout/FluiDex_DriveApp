import SwiftUI
import CoreData

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Register")
                .font(.largeTitle.bold())
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .padding(.horizontal)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button("Create Account") {
                // тут сохраняем пользователя
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
    RegisterView(isLoggedIn: .constant(false), hasSelectedCar: .constant(false))
}
