import SwiftUI
import CoreData

struct ForgotPasswordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var showForgotPassword: Bool

    @State private var email = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Forgot Password")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .cyan.opacity(0.5), radius: 10)

            glowingField("Enter your email", text: $email, icon: "envelope.fill")
                .padding(.horizontal, 40)

            NeonButton(title: "Recover Password") {
                recoverPassword()
            }

            if !message.isEmpty {
                Text(message)
                    .foregroundColor(.white)
                    .font(.footnote)
                    .padding()
            }

            Spacer()
        }
        .padding(.top, 80)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }

    private func recoverPassword() {
        guard !email.isEmpty else {
            message = "Please enter your email"
            return
        }

        let request: NSFetchRequest<User> = User.fetchRequest()
        request.predicate = NSPredicate(format: "email == %@", email.lowercased())

        if let user = try? viewContext.fetch(request).first {
            message = "Your password is: \(user.password ?? "unknown")"
        } else {
            message = "No account found with this email"
        }
    }
}


#Preview {
    ForgotPasswordView(showForgotPassword: .constant(true))
}
