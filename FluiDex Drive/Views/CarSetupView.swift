import SwiftUI

struct CarSetupView: View {
    @AppStorage("selectedCar") private var selectedCar: String = ""
    @AppStorage("carYear") private var carYear: String = ""
    @AppStorage("carMileage") private var carMileage: String = ""
    @AppStorage("carVIN") private var carVIN: String = ""
    @AppStorage("carFuelType") private var carFuelType: String = ""
    @Binding var setupCompleted: Bool

    let fuelTypes = ["Gasoline", "Diesel", "Hybrid", "Electric"]
    @State private var showSavedMessage = false

    var body: some View {
        ZStack {
            // 🌌 Фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                // 🚘 Превью выбранной машины
                VStack(spacing: 12) {
                    if let image = carImage(for: selectedCar) {
                        Image(image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                            .shadow(color: .cyan.opacity(0.6), radius: 20)
                            .transition(.scale)
                    }

                    Text(selectedCar)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.8), radius: 10)
                }
                .padding(.top, 40)
                .animation(.easeInOut(duration: 0.5), value: selectedCar)

                // 🧾 Поля
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
                        Text("Fuel / Power Type")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.leading, 6)

                        Picker("Select Fuel Type", selection: $carFuelType) {
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

                // 💾 Кнопка сохранения
                NeonButton(title: "Save and Continue") {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSavedMessage = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                        withAnimation {
                            setupCompleted = true
                        }
                    }
                }
                .padding(.bottom, 40)

                if showSavedMessage {
                    Text("✅ Car profile saved!")
                        .foregroundColor(Color(hex: "#FFD54F"))
                        .font(.headline)
                        .transition(.opacity.combined(with: .scale))
                        .padding(.bottom, 10)
                }
            }
        }
    }

    // 🏎️ Получаем имя картинки из названия
    private func carImage(for name: String) -> String? {
        let formatted = name.replacingOccurrences(of: " ", with: "")
                             .replacingOccurrences(of: "-", with: "")
        return formatted
    }
}

#Preview {
    CarSetupView(setupCompleted: .constant(false))
}
