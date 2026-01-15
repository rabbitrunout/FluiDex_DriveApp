import SwiftUI
import CoreData

struct CarSetupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("userEmail") private var userEmail: String = ""

    @ObservedObject var car: Car
    var isEditing: Bool = false
    @Binding var setupCompleted: Bool

    @State private var carYear = ""
    @State private var carMileage = ""
    @State private var carVIN = ""
    @State private var carFuelType = ""
    @State private var showSavedMessage = false

    let fuelTypes = ["Gasoline", "Diesel", "Hybrid", "Electric"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                VStack(spacing: 12) {
                    Image(car.imageName ?? "car.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 130)
                        .shadow(color: .cyan.opacity(0.7), radius: 20)

                    Text(car.name ?? "Your Car")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)

                VStack(spacing: 18) {
                    glowingField("Year", text: $carYear, icon: "calendar")
                    glowingField("Mileage (km)", text: $carMileage, icon: "speedometer")
                        .keyboardType(.numberPad)
                    glowingField("VIN (optional)", text: $carVIN, icon: "barcode.viewfinder")

                    Picker("Fuel Type", selection: $carFuelType) {
                        ForEach(fuelTypes, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }

                Spacer()

                NeonButton(title: isEditing ? "Save" : "Save and Continue") {
                    saveCar()
                }
                // ✅ блокируем сохранение если пусто
                .disabled(carYear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || carFuelType.isEmpty)
                .opacity(carYear.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
                .padding(.bottom, 30)

                if showSavedMessage {
                    Text("Saved!")
                        .foregroundColor(.yellow)
                        .transition(.opacity)
                }
            }
        }
        .onAppear { loadCar() }
    }

    private func loadCar() {
        carYear = car.year ?? ""
        carMileage = car.mileage == 0 ? "" : String(car.mileage)
        carVIN = car.vin ?? ""
        carFuelType = car.fuelType ?? "Gasoline"
    }

    private func saveCar() {
        let year = carYear.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !year.isEmpty else { return }

        car.year = year
        car.mileage = Int32(carMileage) ?? 0
        car.vin = carVIN
        car.fuelType = carFuelType
        car.ownerEmail = userEmail

        // ✅ делаем машину активной: снимаем активность с остальных
        let fetch: NSFetchRequest<Car> = Car.fetchRequest()
        if let all = try? viewContext.fetch(fetch) {
            for c in all { c.isSelected = false }
        }
        car.isSelected = true

        do {
            try viewContext.save()

            // ✅ создаём дефолтное расписание ТО для этой машины
            MaintenanceManager.shared.generateDefaultItems(for: car, in: viewContext)

            withAnimation { showSavedMessage = true }
            withAnimation { setupCompleted = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                dismiss()
            }
        } catch {
            print("❌ Save error:", error)
        }
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    let previewCar = Car(context: context)
    previewCar.name = "Jeep Wrangler"
    previewCar.imageName = "Jeep Wrangler"
    return CarSetupView(car: previewCar, setupCompleted: .constant(false))
        .environment(\.managedObjectContext, context)
}
