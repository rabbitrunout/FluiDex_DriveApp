import SwiftUI

// 🚘 Модель данных для списка машин
struct CarModel: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

struct CarSelectionView: View {
    @Binding var hasSelectedCar: Bool
    @AppStorage("selectedCar") private var selectedCar: String = ""
    @State private var showSetup = false

    // ✅ Список машин с изображениями из Assets/Cars
    let cars: [CarModel] = [
        CarModel(name: "Ford F-Series", imageName: "Ford F-Series"),
        CarModel(name: "Audi Q5", imageName: "Audi Q5"),
        CarModel(name: "Audi A4", imageName: "Audi A4"),
        CarModel(name: "Mercedes-Benz GLE", imageName: "Mercedes-Benz GLE"),
        CarModel(name: "Jeep", imageName: "Jeep"),
        CarModel(name: "Hyundai Tucson", imageName: "Hyundai Tucson"),
        CarModel(name: "Jeep Wrangler", imageName: "Jeep Wrangler"),
        CarModel(name: "Dodge Grand Caravan", imageName: "Dodge Grand Caravan"),
        CarModel(name: "Hyundai Elantra", imageName: "Hyundai Elantra"),
        CarModel(name: "Jeep Compass", imageName: "JeepCompass"),
        CarModel(name: "Nissan Rogue", imageName: "Nissan Rogue"),
        CarModel(name: "Volkswagen Golf", imageName: "Volkswagen Golf"),
        CarModel(name: "Mazda CX-5", imageName: "Mazda CX-5"),
        CarModel(name: "Chevrolet Traverse", imageName: "Chevrolet Traverse"),
        CarModel(name: "Kia Sportage", imageName: "Kia Sportage"),
        CarModel(name: "Ford Edge", imageName: "Ford Edge"),
        CarModel(name: "Volvo XC60", imageName: "Volvo XC60"),
        CarModel(name: "BMW X7", imageName: "BMW X7"),
        CarModel(name: "Subaru Outback", imageName: "Subaru Outback")
    ]

    var body: some View {
        ZStack {
            // 🌌 Неоновый фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Text("Select Your Vehicle")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 8)
                    .padding(.top, 30)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
                        ForEach(cars) { car in
                            Button {
                                withAnimation(.easeInOut(duration: 0.4)) {
                                    selectedCar = car.name
                                    showSetup = true
                                }
                            } label: {
                                VStack(spacing: 10) {
                                    Image(car.imageName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                        .cornerRadius(12)
                                        .shadow(color: .cyan.opacity(0.5), radius: 10, y: 6)

                                    Text(car.name)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    ZStack {
                                        Color.white.opacity(0.08)
                                        if selectedCar == car.name {
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color(hex: "#FFD54F"), lineWidth: 2)
                                                .shadow(color: .yellow.opacity(0.7), radius: 10)
                                        }
                                    }
                                )
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.3), radius: 8)
                                .scaleEffect(selectedCar == car.name ? 1.05 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedCar)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        // 🚗 После выбора авто открывается экран настройки
        .fullScreenCover(isPresented: $showSetup) {
            CarSetupView(setupCompleted: $hasSelectedCar)
        }
    }
}

#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
}
