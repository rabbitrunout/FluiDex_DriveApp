import SwiftUI
import CoreData

struct LoginView: View {
    @Binding var isLoggedIn: Bool
    @Binding var showRegister: Bool
    @Binding var showLogin: Bool
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // 💜 Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer()

                // 🚘 Заголовок
                Text("Welcome Back")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 10, y: 4)

                Text("Sign in to your FluiDex account")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.bottom, 20)

                // ✉️ Поля ввода
                VStack(spacing: 18) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Color(hex: "#FFD54F"))
                        TextField("Email", text: $email)
                            .foregroundColor(.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "#FFD54F").opacity(0.6), lineWidth: 1))

                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(Color(hex: "#FFD54F"))
                        SecureField("Password", text: $password)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(15)
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(Color(hex: "#FFD54F").opacity(0.6), lineWidth: 1))
                }
                .padding(.horizontal, 40)

                // ⚠️ Ошибка
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }

                // 🔑 Кнопка входа
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        if email.isEmpty || password.isEmpty {
                            errorMessage = "Please fill in all fields"
                        } else {
                            isLoggedIn = true
                            showLogin = false
                        }
                    }
                }) {
                    Text("Log In")
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

                // 🌈 Кнопка регистрации
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLogin = false
                        showRegister = true
                    }
                }) {
                    Text("Create Account")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        .underline()
                }
                .padding(.top, 5)

                Spacer()
            }
        }
    }
}

#Preview {
    LoginView(
        isLoggedIn: .constant(false),
        showRegister: .constant(false),
        showLogin: .constant(true)
    )
}
