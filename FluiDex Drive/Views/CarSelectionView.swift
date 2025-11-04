import SwiftUI
import CoreData

// MARK: - 🚘 Модель отображаемых машин (для выбора)
struct CarModel: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

// MARK: - 💡 Основное представление выбора машины
struct CarSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var hasSelectedCar: Bool

    @AppStorage("selectedCar") private var selectedCarName: String = ""
    @AppStorage("selectedCarID") private var selectedCarID: String = ""

    @State private var showSetup = false

    // 🚗 Пример списка машин
    let cars: [CarModel] = [
        CarModel(name: "Ford F-Series", imageName: "Ford F-Series"),
        CarModel(name: "Audi Q5", imageName: "Audi Q5"),
        CarModel(name: "Jeep", imageName: "Jeep"),
        CarModel(name: "BMW X7", imageName: "BMW X7"),
        CarModel(name: "Kia Sportage", imageName: "Kia Sportage")
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
                                selectCar(car)
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
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(
                                                    selectedCarName == car.name
                                                    ? Color(hex: "#FFD54F")
                                                    : Color.clear,
                                                    lineWidth: 2
                                                )
                                        )
                                )
                                .shadow(color: .cyan.opacity(0.3), radius: 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        // После выбора открывается экран настройки
        .fullScreenCover(isPresented: $showSetup) {
            CarSetupView(setupCompleted: $hasSelectedCar)
        }
    }

    // MARK: - 🚀 Выбор машины
    private func selectCar(_ car: CarModel) {
        withAnimation(.easeInOut(duration: 0.3)) {
            selectedCarName = car.name
            showSetup = true
        }

        // ❗ Сбрасываем предыдущие выборы
        let fetch: NSFetchRequest<Car> = Car.fetchRequest()
        if let cars = try? viewContext.fetch(fetch) {
            for c in cars { c.isSelected = false }
        }

        // 💾 Создаём и сохраняем новую машину
        let newCar = Car(context: viewContext)
        newCar.id = UUID()
        newCar.name = car.name
        newCar.imageName = car.imageName
        newCar.isSelected = true

        do {
            try viewContext.save()
            UserDefaults.standard.set(newCar.id?.uuidString, forKey: "selectedCarID")
        } catch {
            print("❌ Error saving selected car: \(error.localizedDescription)")
        }
    }
}

#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
