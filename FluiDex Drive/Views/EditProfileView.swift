import SwiftUI

struct EditProfileView: View {
    @Binding var currentName: String
    @Binding var currentEmail: String
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Form {
                    Section(header: Text("Profile Info").foregroundColor(.white)) {
                        TextField("Full Name", text: $currentName)
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)
                            .foregroundColor(.white)

                        TextField("Email", text: $currentEmail)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.none)
                            .foregroundColor(.white)
                    }

                    Section(header: Text("Change Password").foregroundColor(.white)) {
                        SecureField("New Password", text: $newPassword)
                        SecureField("Confirm Password", text: $confirmPassword)
                    }

                    Section {
                        Button("Save Changes") {
                            if newPassword == confirmPassword || newPassword.isEmpty {
                                dismiss()
                            }
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(12)
                        .shadow(color: .yellow.opacity(0.7), radius: 6)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}
