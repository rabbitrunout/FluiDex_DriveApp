import SwiftUI
import CoreData

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showLogin: Bool
    @Binding var showRegister: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 🌌 Неоновый градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer(minLength: 60)

                // 🔷 Заголовок
                Text("Create Account")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12, y: 5)

                // ✨ Поля ввода
                VStack(spacing: 18) {
                    glowingField("Full Name", text: $name, icon: "person.fill")
                    glowingField("Email", text: $email, icon: "envelope.fill")
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    glowingSecureField("Password", text: $password, icon: "lock.fill")
                    glowingSecureField("Confirm Password", text: $confirmPassword, icon: "checkmark.shield.fill")
                }
                .padding(.horizontal, 35)
                .padding(.top, 20)

                // ⚠️ Ошибка
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }

                // 💛 Кнопка регистрации
                NeonButton(title: "Sign Up") {
                    if name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
                        errorMessage = "Please fill in all fields"
                    } else if password != confirmPassword {
                        errorMessage = "Passwords do not match"
                    } else {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            showRegister = false
                            showLogin = true // ⬅️ переход сразу на экран входа
                        }
                    }
                }
                .padding(.top, 25)

                // 🔙 Кнопка "Already have an account?"
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showRegister = false
                        showLogin = true
                    }
                }) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.footnote)
                        .underline()
                }
                .padding(.top, 10)

                Spacer()
            }
        }
    }
}

#Preview {
    RegisterView(
        isLoggedIn: .constant(false),
        hasSelectedCar: .constant(false),
        showLogin: .constant(false),
        showRegister: .constant(true)
    )
}
