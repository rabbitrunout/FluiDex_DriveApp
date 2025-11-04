import SwiftUI
import Combine
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("selectedCar") private var selectedCar: String = ""
    @AppStorage("userName") private var userName: String = "User"
    @AppStorage("userEmail") private var userEmail: String = ""

    @State private var showCarSelection = false
    @State private var isEditing = false
    @State private var tempName = ""
    @State private var tempEmail = ""
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            // 🌌 Фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 25) {
                    // 👤 Профиль
                    VStack(spacing: 10) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.7), radius: 10)

                        if isEditing {
                            glowingField("Full Name", text: $tempName, icon: "person.fill")
                                .padding(.horizontal, 40)
                            glowingField("Email", text: $tempEmail, icon: "envelope.fill")
                                .padding(.horizontal, 40)
                        } else {
                            Text(userName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text(userEmail)
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                        }

                        Button(action: toggleEdit) {
                            Label(isEditing ? "Save Changes" : "Edit Profile",
                                  systemImage: isEditing ? "checkmark.circle.fill" : "pencil")
                                .foregroundColor(Color(hex: "#FFD54F"))
                                .font(.headline)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.top, 40)

                    Divider().overlay(Color.white.opacity(0.3)).padding(.horizontal)

                    // 🚗 Машина
                    VStack(spacing: 15) {
                        HStack {
                            Text("My Vehicle")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button(action: { showCarSelection.toggle() }) {
                                Label("Change", systemImage: "car.2.fill")
                                    .foregroundColor(Color(hex: "#FFD54F"))
                            }
                        }

                        if selectedCar.isEmpty {
                            Button {
                                showCarSelection = true
                            } label: {
                                Text("Select your car")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(hex: "#FFD54F"))
                                    .cornerRadius(20)
                            }
                        } else {
                            HStack {
                                Image(systemName: "car.fill")
                                    .foregroundColor(.yellow)
                                    .font(.title2)
                                Text(selectedCar)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                            .shadow(color: .cyan.opacity(0.3), radius: 10)
                        }
                    }
                    .padding(.horizontal)

                    Divider().overlay(Color.white.opacity(0.3)).padding(.horizontal)

                    // 🚪 Выход
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isLoggedIn = false
                            UserDefaults.standard.set(false, forKey: "isLoggedIn")
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.backward.circle.fill")
                            Text("Log Out")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(30)
                        .shadow(color: .yellow.opacity(0.4), radius: 10, y: 6)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            tempName = userName
            tempEmail = userEmail
        }
        .sheet(isPresented: $showCarSelection) {
            CarSelectionView(hasSelectedCar: .constant(true))
        }
    }

    // MARK: ✏️ Редактирование профиля
    private func toggleEdit() {
        if isEditing {
            // 💾 Сохраняем изменения в UserDefaults
            userName = tempName
            userEmail = tempEmail
            UserDefaults.standard.set(tempName, forKey: "userName")
            UserDefaults.standard.set(tempEmail, forKey: "userEmail")

            // 💾 Сохраняем изменения в Core Data (если пользователь найден)
            let request: NSFetchRequest<User> = User.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", userEmail.lowercased())

            if let user = try? viewContext.fetch(request).first {
                user.name = tempName
                user.email = tempEmail.lowercased()
                try? viewContext.save()
                print("✅ Profile updated for \(user.name ?? "unknown")")
            }
        }

        withAnimation {
            isEditing.toggle()
        }
    }
}

#Preview {
    ProfileView(isLoggedIn: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
