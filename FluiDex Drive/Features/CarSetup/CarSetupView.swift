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

                // HEADER
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

                // FORM
                VStack(spacing: 18) {
                    glowingField("Year", text: $carYear, icon: "calendar")
                    glowingField("Mileage (km)", text: $carMileage, icon: "speedometer")
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
        carMileage = String(car.mileage)
        carVIN = car.vin ?? ""
        carFuelType = car.fuelType ?? "Gasoline"
    }

    private func saveCar() {
        car.year = carYear
        car.mileage = Int32(carMileage) ?? 0
        car.vin = carVIN
        car.fuelType = carFuelType
        car.ownerEmail = userEmail
        car.isSelected = true

        do {
            try viewContext.save()

            // ✅ создаём дефолтное расписание ТО для этой машины
            MaintenanceManager.shared.generateDefaultItems(for: car, in: viewContext)

            withAnimation { showSavedMessage = true }

            withAnimation {
                setupCompleted = true
            }

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
