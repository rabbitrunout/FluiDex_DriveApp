import SwiftUI
import CoreData
import Foundation

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
    @AppStorage("userEmail") private var userEmail: String = ""

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
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150), spacing: 20)],
                        spacing: 20
                    ) {
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
        .fullScreenCover(isPresented: $showSetup) {
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

    private func selectCar(_ model: CarModel) {
        let owner = userEmail
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !owner.isEmpty else {
            print("❌ userEmail empty — cannot assign car to owner")
            return
        }

        // ✅ важно: всё в main context
        viewContext.performAndWait {

            // 1) снять isSelected у всех машин текущего пользователя
            let fetchAll: NSFetchRequest<Car> = Car.fetchRequest()
            fetchAll.predicate = NSPredicate(format: "ownerEmail == %@", owner)
            let userCars = (try? viewContext.fetch(fetchAll)) ?? []
            userCars.forEach { $0.isSelected = false }

            // 2) найти существующую машину, иначе создать
            let fetchExisting: NSFetchRequest<Car> = Car.fetchRequest()
            fetchExisting.fetchLimit = 1
            fetchExisting.predicate = NSPredicate(format: "ownerEmail == %@ AND name == %@", owner, model.name)
            let existing = (try? viewContext.fetch(fetchExisting))?.first

            let carEntity: Car
            if let existing {
                carEntity = existing
            } else {
                let newCar = Car(context: viewContext)
                newCar.id = UUID()
                newCar.name = model.name
                newCar.imageName = model.imageName
                newCar.ownerEmail = owner
                carEntity = newCar
            }

            carEntity.isSelected = true

            do {
                try viewContext.save()

                // ✅ AppStorage только для подписей/лейблов
                selectedCar = carEntity.name ?? model.name
                selectedCarID = carEntity.id?.uuidString ?? ""

                selectedCarEntity = carEntity
                hasSelectedCar = true

                // ✅ форс обновления объектов
                viewContext.refreshAllObjects()

                // ✅ уведомляем ВСЕ экраны
                Foundation.NotificationCenter.default.post(
                    name: Foundation.Notification.Name.activeCarChanged,
                    object: nil
                )

                showSetup = true
            } catch {
                print("❌ Error saving:", error)
            }
        }
    }
}

#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
