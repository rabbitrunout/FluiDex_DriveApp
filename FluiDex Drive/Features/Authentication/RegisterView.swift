import SwiftUI
import CoreData
import Combine   // ✅ добавь



struct RegisterView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showLogin: Bool
    @Binding var showRegister: Bool
    @Binding var showWelcomeAnimation: Bool

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer(minLength: 60)

                Text("Create Account")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12, y: 5)

                VStack(spacing: 18) {
                    glowingField("Full Name", text: $name, icon: "person.fill")

                    glowingField("Email", text: $email, icon: "envelope.fill")
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    Divider()
                        .background(Color.cyan.opacity(0.3))
                        .padding(.horizontal, 10)

                    GlowingSecureField(placeholder: "Password", icon: "lock.fill", text: $password)
                    GlowingSecureField(placeholder: "Confirm Password", icon: "checkmark.shield.fill", text: $confirmPassword)
                }
                .padding(.horizontal, 35)
                .padding(.top, 20)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 5)
                }

                NeonButton(title: isSaving ? "Creating..." : "Sign Up") {
                    registerUser()
                }
                .disabled(isSaving)
                .padding(.top, 25)

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

    private func registerUser() {
        errorMessage = ""

        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        guard !cleanName.isEmpty, !cleanEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            return
        }

        isSaving = true

        // ✅ Сброс прошлой "сессии"
        UserDefaults.standard.removeObject(forKey: "selectedCar")
        UserDefaults.standard.removeObject(forKey: "selectedCarID")
        UserDefaults.standard.set(false, forKey: "hasSelectedCar")
        UserDefaults.standard.set(false, forKey: "setupCompleted")
        hasSelectedCar = false

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email == %@", cleanEmail)

        do {
            let existing = try viewContext.fetch(request)
            if !existing.isEmpty {
                errorMessage = "Email already registered"
                isSaving = false
                return
            }

            let newUser = User(context: viewContext)
            newUser.id = UUID()
            newUser.name = cleanName
            newUser.email = cleanEmail
            newUser.password = password
            newUser.createdAt = Date()

            try viewContext.save()

            // ✅ данные пользователя в UserDefaults
            UserDefaults.standard.set(newUser.name, forKey: "userName")
            UserDefaults.standard.set(newUser.email, forKey: "userEmail")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")

            withAnimation(.easeInOut(duration: 0.5)) {
                showRegister = false
                showWelcomeAnimation = true
                isLoggedIn = true
                hasSelectedCar = false
            }

        } catch {
            errorMessage = "Error saving user: \(error.localizedDescription)"
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

