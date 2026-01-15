import SwiftUI
import CoreData

struct CarModel: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
}

struct CarSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var hasSelectedCar: Bool

    @AppStorage("selectedCar") private var selectedCar: String = ""
    @AppStorage("selectedCarID") private var selectedCarID: String = ""

    @State private var showSetup = false
    @State private var selectedCarEntity: Car? = nil
    @State private var cars: [CarModel] = []

    var body: some View {
        ZStack {
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
                    .shadow(color: .cyan.opacity(0.8), radius: 10)
                    .padding(.top, 30)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 20)], spacing: 20) {
                        ForEach(cars) { car in
                            Button { selectCar(car) } label: {
                                CarCardView(car: car, selectedCarName: selectedCar)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .fullScreenCover(isPresented: $showSetup, onDismiss: {
            // ✅ если пользователь закрыл setup без Save — откатим черновик
            if selectedCarEntity != nil {
                viewContext.rollback()
                selectedCarEntity = nil
            }
        }) {
            if let car = selectedCarEntity {
                CarSetupView(car: car, isEditing: false, setupCompleted: $hasSelectedCar)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .onAppear { loadCars() }
    }

    private func loadCars() {
        let names = [
            "Audi A4", "Audi Q5", "BMW X7", "BMWX5",
            "Ford Edge", "Ford F-Series", "GMC Sierra",
            "Honda Civic", "Hyundai Elantra", "Jeep Wrangler",
            "Kia Sportage", "Lexus RX 350", "Mazda CX-5",
            "Mercedes-Benz GLE", "Toyota RAV4", "Nissan Rogue"
        ]
        cars = names.map { CarModel(name: $0, imageName: $0) }
    }

    // ✅ Select car: создаём DRAFT (без save) → открываем setup
    private func selectCar(_ model: CarModel) {
        // UI подсветка
        selectedCar = model.name

        // снимаем выделение со всех машин (в контексте)
        let fetch: NSFetchRequest<Car> = Car.fetchRequest()
        if let all = try? viewContext.fetch(fetch) {
            for c in all { c.isSelected = false }
        }

        let draft = Car(context: viewContext)
        draft.id = UUID()
        draft.name = model.name
        draft.imageName = model.imageName
        draft.isSelected = true

        // ❗️НЕ сохраняем здесь

        selectedCarID = draft.id?.uuidString ?? ""
        selectedCarEntity = draft

        hasSelectedCar = true
        showSetup = true
    }
}

#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
