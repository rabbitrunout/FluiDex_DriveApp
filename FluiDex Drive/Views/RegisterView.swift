import SwiftUI
import CoreData

struct RegisterView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(entity: User.entity(), sortDescriptors: [])
    private var users: FetchedResults<User>

    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showLogin: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 🩵 Заголовок
                Text("Create Account")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                    .padding(.top, 30)

                // ✨ Поля ввода
                VStack(spacing: 18) {
                    inputField(icon: "person.fill", placeholder: "Full Name", text: $name)
                    inputField(icon: "envelope.fill", placeholder: "Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    secureInputField(icon: "lock.fill", placeholder: "Password", text: $password)
                    secureInputField(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPassword)
                }
                .padding(.horizontal, 40)

                // 🔴 Сообщение об ошибке
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 5)
                }

                // 🟢 Успешная регистрация
                if !successMessage.isEmpty {
                    Text(successMessage)
                        .foregroundColor(.green)
                        .font(.caption)
                        .padding(.top, 5)
                }

                // 💛 Кнопка регистрации
                Button(action: registerUser) {
                    Text("Sign Up")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .foregroundColor(.black)
                        .cornerRadius(30)
                        .shadow(color: .yellow.opacity(0.4), radius: 10, y: 5)
                }
                .padding(.horizontal, 50)
                .padding(.top, 20)

                // 🔹 Ссылка на логин
                Button(action: {
                    showLogin = true
                }) {
                    Text("Already have an account? Log In")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.footnote)
                        .underline()
                }
                .padding(.top, 10)

                Spacer()
            }
        }
    }

    // MARK: - Регистрация пользователя
    private func registerUser() {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            successMessage = ""
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            successMessage = ""
            return
        }

        // Проверка на дубликат
        if users.contains(where: { $0.email == email }) {
            errorMessage = "This email is already registered"
            successMessage = ""
            return
        }

        // 💾 Сохраняем нового пользователя
        let newUser = User(context: context)
        newUser.name = name
        newUser.email = email
        newUser.password = password
        newUser.createdAt = Date()

        do {
            try context.save()
            successMessage = "Account created successfully!"
            errorMessage = ""
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isLoggedIn = true
                hasSelectedCar = false
            }
        } catch {
            errorMessage = "Error saving user: \(error.localizedDescription)"
            successMessage = ""
        }
    }

    // MARK: - Общие поля
    // MARK: - Текстовое поле с иконкой
    private func inputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan.opacity(0.8))
                .frame(width: 28)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                TextField("", text: text)
                    .foregroundColor(.white)
                    .accentColor(.cyan)
            }
        }
        .padding()
        .font(.system(size: 18, weight: .medium))
        .background(Color.white.opacity(0.12))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
        )
        .shadow(color: Color.cyan.opacity(0.25), radius: 6)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.never)
    }

    // MARK: - Поле для пароля с иконкой
    private func secureInputField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan.opacity(0.8))
                .frame(width: 28)
            ZStack(alignment: .leading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color.white.opacity(0.6))
                }
                SecureField("", text: text)
                    .foregroundColor(.white)
                    .accentColor(.cyan)
            }
        }
        .padding()
        .font(.system(size: 18, weight: .medium))
        .background(Color.white.opacity(0.12))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cyan.opacity(0.7), lineWidth: 1.5)
        )
        .shadow(color: Color.cyan.opacity(0.25), radius: 6)
    }

}

#Preview {
    RegisterView(
        isLoggedIn: .constant(false),
        hasSelectedCar: .constant(false),
        showLogin: .constant(false)
    )
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
