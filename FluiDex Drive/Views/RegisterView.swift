import SwiftUI

struct RegisterView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showLogin: Bool

    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 🌌 Градиентный фон — тот же, что и в WelcomeView
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer(minLength: 60)

                // 🚗 Заголовок
                Text("Create Account")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12, y: 4)

                Text("Join FluiDex Drive today")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 10)

                // ✏️ Поля ввода
                VStack(spacing: 18) {
                    field(icon: "person.fill", placeholder: "Full Name", text: $fullName)
                    field(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    secureField(icon: "lock.fill", placeholder: "Password", text: $password)
                    secureField(icon: "lock.rotation.open", placeholder: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal, 40)
                .padding(.top, 10)

                // ⚠️ Сообщение об ошибке
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }

                // 💛 Кнопка регистрации
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        if fullName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty {
                            errorMessage = "Please fill in all fields"
                        } else if password != confirmPassword {
                            errorMessage = "Passwords do not match"
                        } else {
                            errorMessage = ""
                            isLoggedIn = true
                            hasSelectedCar = false
                        }
                    }
                }) {
                    Text("Create Account")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .foregroundColor(.black)
                        .cornerRadius(30)
                        .shadow(color: Color.yellow.opacity(0.5), radius: 12, y: 6)
                }
                .padding(.horizontal, 50)
                .padding(.top, 25)

                // 🔙 Кнопка возврата к логину
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLogin = true
                    }
                }) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        .underline()
                }
                .padding(.top, 5)

                Spacer()
            }
        }
    }

    // MARK: - Вспомогательные поля
    private func field(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#FFD54F"))
            TextField(placeholder, text: text)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15)
            .stroke(Color(hex: "#FFD54F").opacity(0.6), lineWidth: 1))
    }

    private func secureField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#FFD54F"))
            SecureField(placeholder, text: text)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .semibold))
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(15)
        .overlay(RoundedRectangle(cornerRadius: 15)
            .stroke(Color(hex: "#FFD54F").opacity(0.6), lineWidth: 1))
    }
}

#Preview {
    RegisterView(
        isLoggedIn: .constant(false),
        hasSelectedCar: .constant(false),
        showLogin: .constant(false)
    )
}
