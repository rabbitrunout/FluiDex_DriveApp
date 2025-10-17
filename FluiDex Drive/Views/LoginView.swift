import SwiftUI

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showRegister: Bool
    @Binding var showLogin: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 🌌 Фон в неоновом стиле
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer(minLength: 60)

                // 🩵 Заголовок
                Text("Welcome Back")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12, y: 5)

                // ✨ Поля
                VStack(spacing: 18) {
                    glowingField("Email", text: $email, icon: "envelope.fill")
                    glowingSecureField("Password", text: $password, icon: "lock.fill")
                }
                .padding(.horizontal, 35)
                .padding(.top, 20)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }

                // 💛 Кнопка входа
                NeonButton(title: "Log In") {
                    if email.isEmpty || password.isEmpty {
                        errorMessage = "Please fill in all fields"
                    } else {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isLoggedIn = true
                            hasSelectedCar = false
                            showLogin = false
                        }
                    }
                }
                .padding(.top, 25)

                // 🔙 Кнопка перехода на регистрацию
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLogin = false
                        showRegister = true
                    }
                }) {
                    Text("Don’t have an account? Sign Up")
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
    LoginView(
        isLoggedIn: .constant(false),
        hasSelectedCar: .constant(false),
        showRegister: .constant(false),
        showLogin: .constant(true)
    )
}
