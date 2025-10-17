import SwiftUI
import CoreData

struct CarSelectionView: View {
    @Binding var hasSelectedCar: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // 🔹 Пример списка машин (можно позже подгружать из CoreData или API)
    let cars = [
        ("BMW X5", "BMWX5", "Luxury SUV with comfort and style", "#42A5F5"),
        ("Toyota Corolla", "ToyotaCorolla", "Reliable daily car", "#FFD54F"),
        ("Jeep Compass", "JeepCompass", "Adventure-ready compact SUV", "#FF7043"),
        ("Mazda CX-5", "MazdaCX5", "Sporty crossover for families", "#81D4FA")
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
                Text("Select Your Car")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 10, y: 5)
                    .padding(.top, 50)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        ForEach(cars, id: \.0) { car in
                            CarCard(
                                title: car.0,
                                imageName: car.1,
                                description: car.2,
                                colorHex: car.3
                            ) {
                                selectCar(named: car.0)
                            }
                        }
                    }
                    .padding(.horizontal, 25)
                    .padding(.bottom, 60)
                }
            }
        }
    }

    // 🧠 Сохраняем выбор машины
    private func selectCar(named name: String) {
        withAnimation(.easeInOut(duration: 0.4)) {
            hasSelectedCar = true
        }
        print("✅ Selected car: \(name)")
    }
}

#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
}
