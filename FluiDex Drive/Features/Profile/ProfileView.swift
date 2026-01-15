import SwiftUI
import CoreData

struct ProfileView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("selectedCar") private var selectedCar: String = ""
    @AppStorage("selectedCarID") private var selectedCarID: String = ""
    @AppStorage("userName") private var userName: String = "User"
    @AppStorage("userEmail") private var userEmail: String = ""

    @Binding var isLoggedIn: Bool

    @State private var showCarSelection = false
    @State private var isEditing = false
    @State private var tempName = ""
    @State private var tempEmail = ""
    @State private var carToEdit: Car? = nil

    @FetchRequest(sortDescriptors: [], predicate: nil, animation: .easeInOut)
    private var allCars: FetchedResults<Car>

    private var owner: String {
        userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var visibleCars: [Car] {
        allCars.filter {
            ($0.ownerEmail ?? "").lowercased() == owner &&
            !($0.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

    // MARK: - Header

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

    // MARK: - Garage Section

    private var myGarageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("My Garage")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button { showCarSelection = true } label: {
                    Label("Add Car", systemImage: "plus.circle.fill")
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
            }
            .padding(.horizontal, 20)

            if visibleCars.isEmpty {
                VStack(spacing: 10) {
                    Text("No car selected")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.white)

                    Text("Add your first car to start tracking maintenance.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    NeonButton(title: "Add your first car") {
                        showCarSelection = true
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 60)
                }
                .padding(.top, 10)

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

    // MARK: - Active Car (ONE VERSION)

    private func setActiveCar(_ car: Car) {
        // Глобально снимаем isSelected, чтобы нигде не прилипала чужая активная машина
        for c in allCars { c.isSelected = false }
        car.isSelected = true

        selectedCar = car.name ?? ""
        selectedCarID = car.id?.uuidString ?? ""

        do {
            try viewContext.save()
        } catch {
            print("❌ CoreData save error in setActiveCar:", error)
        }

        UserDefaults.standard.set(true, forKey: "hasSelectedCar")
        UserDefaults.standard.set(true, forKey: "setupCompleted")
    }

    // MARK: - Logout (ONE VERSION)

    private var logoutButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.4)) {
                for c in allCars { c.isSelected = false }

                do {
                    try viewContext.save()
                } catch {
                    print("❌ CoreData save error on logout:", error)
                }

                isLoggedIn = false
                UserDefaults.standard.set(false, forKey: "isLoggedIn")

                UserDefaults.standard.removeObject(forKey: "selectedCar")
                UserDefaults.standard.removeObject(forKey: "selectedCarID")
                UserDefaults.standard.set(false, forKey: "hasSelectedCar")
                UserDefaults.standard.set(false, forKey: "setupCompleted")
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

    // MARK: - Fix selection (ONE VERSION)

    private func fixSelectionIfNeeded() {
        guard !visibleCars.isEmpty else {
            selectedCar = ""
            selectedCarID = ""
            UserDefaults.standard.set(false, forKey: "hasSelectedCar")
            UserDefaults.standard.set(false, forKey: "setupCompleted")

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showCarSelection = true
            }
            return
        }

        if visibleCars.first(where: { $0.isSelected }) == nil,
           let first = visibleCars.first {
            setActiveCar(first)
        }
    }

    // MARK: - Summary

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

    // MARK: - Actions

    private func toggleEdit() {
        if isEditing {
            userName = tempName
            userEmail = tempEmail
            UserDefaults.standard.set(tempName, forKey: "userName")
            UserDefaults.standard.set(tempEmail, forKey: "userEmail")

            do {
                try viewContext.save()
            } catch {
                print("❌ CoreData save error in toggleEdit:", error)
            }
        }
        withAnimation { isEditing.toggle() }
    }

    private func editCarInfo(_ car: Car) {
        carToEdit = car
    }

    private func deleteCar(_ car: Car) {
        let wasSelected = car.isSelected
        let deletingID = car.objectID

        withAnimation {
            viewContext.delete(car)
            do {
                try viewContext.save()
            } catch {
                print("❌ CoreData save error in deleteCar:", error)
            }
        }

        let remaining = visibleCars.filter { $0.objectID != deletingID }

        if wasSelected {
            if let next = remaining.first {
                setActiveCar(next)
            } else {
                selectedCar = ""
                selectedCarID = ""
                UserDefaults.standard.set(false, forKey: "hasSelectedCar")
                UserDefaults.standard.set(false, forKey: "setupCompleted")

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showCarSelection = true
                }
            }
        }
    }
}

#Preview {
    ProfileView(isLoggedIn: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
