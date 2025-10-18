import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("selectedCar") private var selectedCar: String = ""
    @AppStorage("userName") private var userName: String = "User"
    @AppStorage("userEmail") private var userEmail: String = ""

    @State private var showCarSelection = false
    @Binding var isLoggedIn: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 25) {
                    // 👤 User Info
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 90, height: 90)
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.7), radius: 10)

                        Text(userName)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        Text(userEmail)
                            .foregroundColor(.white.opacity(0.7))
                            .font(.subheadline)
                    }
                    .padding(.top, 40)

                    Divider().background(.white.opacity(0.3)).padding(.horizontal)

                    // 🚘 Vehicle Info
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

                    Divider().background(.white.opacity(0.3)).padding(.horizontal)

                    // 🚪 Logout Button
                    Button {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            isLoggedIn = false
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
                        .shadow(color: Color.yellow.opacity(0.4), radius: 10, y: 6)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 50)
                }
            }
        }
        .sheet(isPresented: $showCarSelection) {
            CarSelectionView(hasSelectedCar: .constant(true))
        }
    }
}

#Preview {
    ProfileView(isLoggedIn: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
