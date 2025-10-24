import SwiftUI
import CoreData

struct LoginView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showRegister: Bool
    @Binding var showLogin: Bool

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var showForgotPassword = false

    var body: some View {
        ZStack {
            // 🌌 Неоновый фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer(minLength: 60)

                // 🔷 Заголовок
                Text("Welcome Back")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12, y: 5)

                // ✨ Поля
                VStack(spacing: 18) {
                    glowingField("Email", text: $email, icon: "envelope.fill")
                    GlowingSecureField(placeholder: "Password", icon: "lock.fill", text: $password)
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

                // 💛 Вход
                NeonButton(title: "Log In") {
                    logInUser()
                }
                .padding(.top, 25)

                // 🔵 Забыли пароль
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .foregroundColor(Color(hex: "#FFD54F"))
                        .font(.footnote)
                        .underline()
                }
                .padding(.top, 8)

                // 🔙 Регистрация
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showLogin = false
                        showRegister = true
                    }
                } label: {
                    Text("Don’t have an account? Sign Up")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.footnote)
                        .underline()
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(showForgotPassword: $showForgotPassword)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: 💾 Авторизация пользователя
    private func logInUser() {
        errorMessage = ""

        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@ AND password == %@", email.lowercased(), password)

        do {
            if let user = try viewContext.fetch(request).first {
                // ✅ Сохраняем данные пользователя
                UserDefaults.standard.set(user.name, forKey: "userName")
                UserDefaults.standard.set(user.email, forKey: "userEmail")
                UserDefaults.standard.set(true, forKey: "isLoggedIn")

                withAnimation(.easeInOut(duration: 0.4)) {
                    isLoggedIn = true
                    hasSelectedCar = false
                    showLogin = false
                }
            } else {
                errorMessage = "Invalid email or password"
            }
        } catch {
            errorMessage = "Login error: \(error.localizedDescription)"
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
    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
