import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("selectedCar") private var selectedCar: String = ""
    @AppStorage("selectedCarID") private var selectedCarID: String = ""
    @AppStorage("userName") private var userName: String = "User"
    @AppStorage("userEmail") private var userEmail: String = ""

    @FetchRequest(
        sortDescriptors: [],
        predicate: nil,
        animation: .easeInOut
    ) private var allCars: FetchedResults<Car>

    @State private var showCarSelection = false
    @State private var isEditing = false
    @State private var tempName = ""
    @State private var tempEmail = ""
    @Binding var isLoggedIn: Bool

    @State private var carToEdit: Car? = nil

    // ✅ показываем только “валидные” машины (без пустых)
    private var visibleCars: [Car] {
        allCars.filter {
            let name = ($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return !name.isEmpty
        }
    }

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
                    profileHeader
                    Divider().overlay(Color.white.opacity(0.3)).padding(.horizontal)
                    myGarageSection
                    Divider().overlay(Color.white.opacity(0.3)).padding(.horizontal)
                    logoutButton
                }
            }
        }
        .onAppear {
            tempName = userName
            tempEmail = userEmail

            // ✅ страховка: если активной машины больше нет — выберем другую или очистим
            fixSelectionIfNeeded()
        }
        .sheet(isPresented: $showCarSelection) {
            CarSelectionView(hasSelectedCar: $showCarSelection)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $carToEdit) { car in
            CarSetupView(car: car, isEditing: true, setupCompleted: .constant(false))
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: Profile Header
    private var profileHeader: some View {
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
    }

    // MARK: My Garage
    private var myGarageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Garage")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button { showCarSelection.toggle() } label: {
                    Label("Add Car", systemImage: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
            }
            .padding(.horizontal, 20)

            if visibleCars.isEmpty {
                Text("No cars added yet.")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(visibleCars) { car in
                            carCard(for: car)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                if let activeCar = visibleCars.first(where: { $0.isSelected }) {
                    garageSummarySection(for: activeCar)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.4), value: activeCar.objectID)
                } else if let first = visibleCars.first {
                    // ✅ если вдруг нет active — показываем первую и сразу делаем active
                    garageSummarySection(for: first)
                        .onAppear { setActiveCar(first) }
                }
            }
        }
    }

    private func carCard(for car: Car) -> some View {
        let isActive = car.isSelected

        return VStack(spacing: 8) {
            Image(car.imageName ?? "car.fill")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
                .cornerRadius(12)
                .shadow(color: isActive ? .yellow.opacity(0.8) : .cyan.opacity(0.4), radius: 10)

            Text(car.name ?? "Unknown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isActive ? Color(hex: "#FFD54F") : .white)

            if isActive {
                Text("Active")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.8), radius: 4)
            }
        }
        .padding()
        .frame(width: 140)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .shadow(color: .cyan.opacity(0.3), radius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isActive ? Color(hex: "#FFD54F") : .clear, lineWidth: 2)
        )
        .onTapGesture { setActiveCar(car) }
    }

    @ViewBuilder
    private func garageSummarySection(for car: Car) -> some View {
        VStack(spacing: 10) {
            Text("Garage Summary")
                .font(.headline)
                .foregroundColor(.white.opacity(0.9))
                .padding(.top, 10)

            VStack(spacing: 12) {
                HStack { Label("Year", systemImage: "calendar"); Spacer(); Text(car.year ?? "—") }
                HStack { Label("Fuel Type", systemImage: "fuelpump"); Spacer(); Text(car.fuelType ?? "—") }
                HStack { Label("Mileage", systemImage: "speedometer"); Spacer(); Text("\(car.mileage) km") }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
                    .shadow(color: .cyan.opacity(0.4), radius: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: "#FFD54F").opacity(0.6), lineWidth: 1)
            )
            .padding(.horizontal, 30)

            HStack(spacing: 20) {
                Button { editCarInfo(car) } label: {
                    Label("Edit Info", systemImage: "pencil.circle.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(20)
                        .shadow(color: .yellow.opacity(0.4), radius: 10, y: 5)
                }

                Button { deleteCar(car) } label: {
                    Label("Delete", systemImage: "trash.fill")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(20)
                        .shadow(color: .red.opacity(0.6), radius: 10, y: 5)
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }

    // MARK: Active car
    private func setActiveCar(_ car: Car) {
        for c in visibleCars { c.isSelected = false }
        car.isSelected = true

        selectedCar = car.name ?? ""
        selectedCarID = car.id?.uuidString ?? ""

        try? viewContext.save()
    }

    // MARK: Logout
    private var logoutButton: some View {
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

    // MARK: Save profile
    private func toggleEdit() {
        if isEditing {
            userName = tempName
            userEmail = tempEmail
            UserDefaults.standard.set(tempName, forKey: "userName")
            UserDefaults.standard.set(tempEmail, forKey: "userEmail")
            try? viewContext.save()
        }
        withAnimation { isEditing.toggle() }
    }

    private func editCarInfo(_ car: Car) {
        carToEdit = car
    }

    // ✅ Удаление машины: переключаем active или чистим AppStorage
    private func deleteCar(_ car: Car) {
        let wasSelected = car.isSelected

        withAnimation {
            viewContext.delete(car)
            try? viewContext.save()
        }

        if wasSelected {
            // после удаления выбираем другую как active
            let remaining = visibleCars.filter { $0 != car }
            if let next = remaining.first {
                setActiveCar(next)
            } else {
                // машин больше нет → чистим выбор
                selectedCar = ""
                selectedCarID = ""
                // если у тебя есть логика “setup completed” в AppEntryView — можно сбросить:
                UserDefaults.standard.set(false, forKey: "setupCompleted")
            }
        }
    }

    // ✅ если selection сломался (удалили активную в другом месте)
    private func fixSelectionIfNeeded() {
        if visibleCars.isEmpty {
            selectedCar = ""
            selectedCarID = ""
            return
        }

        // если нет active — делаем первую active
        if visibleCars.first(where: { $0.isSelected }) == nil, let first = visibleCars.first {
            setActiveCar(first)
        }
    }
}

#Preview {
    ProfileView(isLoggedIn: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
