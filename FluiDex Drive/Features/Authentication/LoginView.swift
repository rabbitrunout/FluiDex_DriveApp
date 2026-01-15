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
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Spacer(minLength: 60)

                Text("Welcome Back")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 12, y: 5)

                VStack(spacing: 18) {
                    glowingField("Email", text: $email, icon: "envelope.fill")
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    GlowingSecureField(placeholder: "Password", icon: "lock.fill", text: $password)
                }
                .padding(.horizontal, 35)
                .padding(.top, 20)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .padding(.top, 5)
                }

                NeonButton(title: "Log In") {
                    logInUser()
                }
                .padding(.top, 25)

                Button { showForgotPassword = true } label: {
                    Text("Forgot Password?")
                        .foregroundColor(Color(hex: "#FFD54F"))
                        .font(.footnote)
                        .underline()
                }
                .padding(.top, 8)

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

    private func logInUser() {
        errorMessage = ""

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanPassword = password

        guard !cleanEmail.isEmpty, !cleanPassword.isEmpty else {
            errorMessage = "Please fill in all fields"
            return
        }

        // ✅ reset session
        UserDefaults.standard.removeObject(forKey: "selectedCar")
        UserDefaults.standard.removeObject(forKey: "selectedCarID")
        UserDefaults.standard.set(false, forKey: "hasSelectedCar")
        UserDefaults.standard.set(false, forKey: "setupCompleted")
        hasSelectedCar = false

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email == %@ AND password == %@", cleanEmail, cleanPassword)

        do {
            guard let user = try viewContext.fetch(request).first else {
                errorMessage = "Invalid email or password"
                return
            }

            let owner = (user.email ?? cleanEmail).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            UserDefaults.standard.set(user.name ?? "User", forKey: "userName")
            UserDefaults.standard.set(owner, forKey: "userEmail")
            UserDefaults.standard.set(true, forKey: "isLoggedIn")

            // ✅ fetch only THIS user's cars
            let carFetch: NSFetchRequest<Car> = Car.fetchRequest()
            carFetch.predicate = NSPredicate(format: "ownerEmail == %@", owner)
            let userCars = try viewContext.fetch(carFetch)

            let selected = userCars.filter { $0.isSelected }
            if let active = selected.first ?? userCars.first {
                userCars.forEach { $0.isSelected = false }
                active.isSelected = true
                try? viewContext.save()

                UserDefaults.standard.set(active.name ?? "", forKey: "selectedCar")
                UserDefaults.standard.set(active.id?.uuidString ?? "", forKey: "selectedCarID")
                UserDefaults.standard.set(true, forKey: "hasSelectedCar")
                UserDefaults.standard.set(true, forKey: "setupCompleted")
                hasSelectedCar = true
            } else {
                UserDefaults.standard.set(false, forKey: "hasSelectedCar")
                UserDefaults.standard.set(false, forKey: "setupCompleted")
                hasSelectedCar = false
            }

            withAnimation(.easeInOut(duration: 0.4)) {
                isLoggedIn = true
                showLogin = false
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
