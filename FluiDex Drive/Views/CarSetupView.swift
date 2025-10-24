import SwiftUI
import CoreData

struct CarSetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userEmail") private var userEmail: String = ""
    @Binding var setupCompleted: Bool

    @State private var carYear = ""
    @State private var carMileage = ""
    @State private var carVIN = ""
    @State private var carFuelType = ""
    @State private var selectedCar = ""
    @State private var showSavedMessage = false

    let fuelTypes = ["Gasoline", "Diesel", "Hybrid", "Electric"]

    init(setupCompleted: Binding<Bool>) {
        _setupCompleted = setupCompleted
        _selectedCar = State(initialValue: UserDefaults.standard.string(forKey: "selectedCar") ?? "")
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                // 🚘 Превью
                VStack(spacing: 12) {
                    if let image = tryLoadCarImage(named: selectedCar) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .shadow(color: .cyan.opacity(0.6), radius: 20)
                    } else {
                        Image(systemName: "car.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .foregroundColor(.yellow.opacity(0.8))
                            .shadow(color: .cyan.opacity(0.6), radius: 15)
                    }

                    Text(selectedCar)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.8), radius: 10)
                }
                .padding(.top, 40)

                VStack(spacing: 18) {
                    glowingField("Year of Manufacture", text: $carYear, icon: "calendar")
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    glowingField("Current Mileage (km)", text: $carMileage, icon: "speedometer")
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    glowingField("VIN (optional)", text: $carVIN, icon: "barcode.viewfinder")
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Fuel Type")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.leading, 6)

                        Picker("Select", selection: $carFuelType) {
                            ForEach(fuelTypes, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }

                Spacer()

                NeonButton(title: "Save and Continue") {
                    saveCarProfile()
                }
                .padding(.bottom, 40)

                if showSavedMessage {
                    Text("✅ Car saved successfully!")
                        .foregroundColor(Color(hex: "#FFD54F"))
                        .font(.headline)
                        .transition(.opacity.combined(with: .scale))
                        .padding(.bottom, 10)
                }
            }
        }
    }

    private func saveCarProfile() {
        let newCar = Car(context: viewContext)
        newCar.id = UUID()
        newCar.name = selectedCar
        newCar.imageName = selectedCar
        newCar.year = carYear
        newCar.mileage = Int32(carMileage) ?? 0
        newCar.vin = carVIN
        newCar.fuelType = carFuelType
        newCar.ownerEmail = userEmail
        newCar.isSelected = true
        try? viewContext.save()

        do {
            // Сбрасываем все остальные машины как неактивные
            let fetchRequest: NSFetchRequest<Car> = Car.fetchRequest()
            if let cars = try? viewContext.fetch(fetchRequest) {
                for car in cars where car.ownerEmail == userEmail {
                    car.isSelected = false
                }
            }

            try viewContext.save()
            withAnimation {
                showSavedMessage = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                withAnimation {
                    setupCompleted = true
                }
            }
        } catch {
            print("❌ Error saving car: \(error.localizedDescription)")
        }
    }

    private func tryLoadCarImage(named name: String) -> Image? {
        if UIImage(named: name) != nil {
            return Image(name)
        }
        let compact = name.replacingOccurrences(of: " ", with: "")
        if UIImage(named: compact) != nil {
            return Image(compact)
        }
        return nil
    }
}


#Preview {
    CarSetupView(setupCompleted: .constant(false))
}
