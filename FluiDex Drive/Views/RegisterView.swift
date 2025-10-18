import SwiftUI
import CoreData

struct RegisterView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showLogin: Bool
    @Binding var showRegister: Bool
    @Binding var showWelcomeAnimation: Bool  // 👈 новый флаг для приветствия

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            // 🌌 Неоновый градиент
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

                // ✨ Поля
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
                NeonButton(title: isSaving ? "Creating..." : "Sign Up") {
                    registerUser()
                }
                .disabled(isSaving)
                .padding(.top, 25)

                // 🔙 Вход
                Button {
                    withAnimation {
                        showRegister = false
                        showLogin = true
                    }
                } label: {
                    Text("Already have an account? Log In")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.footnote)
                        .underline()
                }

                Spacer()
            }
        }
    }

    // MARK: 💾 Регистрация
    private func registerUser() {
        errorMessage = ""
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isSaving = true

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())

        do {
            let existing = try viewContext.fetch(request)
            if !existing.isEmpty {
                errorMessage = "Email already registered"
                isSaving = false
                return
            }

            let newUser = User(context: viewContext)
            newUser.id = UUID()
            newUser.name = name
            newUser.email = email.lowercased()
            newUser.password = password
            newUser.createdAt = Date()

            try viewContext.save()
            print("✅ User registered: \(name)")

            // 🚀 Показ приветственного экрана
            withAnimation {
                showWelcomeAnimation = true
                showRegister = false
            }

        } catch {
            errorMessage = "Error: \(error.localizedDescription)"
            print("❌ Registration failed: \(error)")
        }

        isSaving = false
    }
}

#Preview {
    RegisterView(
        isLoggedIn: .constant(false),
        hasSelectedCar: .constant(false),
        showLogin: .constant(false),
        showRegister: .constant(true),
        showWelcomeAnimation: .constant(false)
    )
    .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
