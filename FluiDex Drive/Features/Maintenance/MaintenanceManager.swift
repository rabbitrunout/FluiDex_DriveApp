import Foundation
import CoreData

final class MaintenanceManager {
    static let shared = MaintenanceManager()
    private init() {}

    // ✅ НЕ сохраняем контекст внутри — это важно (иначе много лишних save)
    func updateNextService(for item: MaintenanceItem) {
        let calendar = Calendar.current

        // next date
        if item.intervalDays > 0 {
            item.nextChangeDate = calendar.date(
                byAdding: .day,
                value: Int(item.intervalDays),
                to: item.lastChangeDate ?? Date()
            )
        } else {
            // fallback
            item.nextChangeDate = calendar.date(byAdding: .day, value: 180, to: item.lastChangeDate ?? Date())
        }

        // next mileage (если используешь)
        if item.intervalKm > 0 {
            item.nextChangeMileage = item.lastChangeMileage + item.intervalKm
        }
    }

    // ✅ Создаём дефолты без дублей + один save в конце
    func generateDefaultItems(for car: Car, in context: NSManagedObjectContext) {

        let defaults: [(title: String, category: String, days: Int)] = [
            ("Engine Oil", "Fluids", 180),
            ("Brake Fluid", "Fluids", 365),
            ("Coolant", "Fluids", 365),
            ("Air Filter", "Filters", 180),
            ("Cabin Filter", "Filters", 180),
            ("Transmission Fluid", "Fluids", 730),
            ("Tire Rotation", "Tires", 180),
            ("Battery Check", "Electrical", 365)
        ]

        for def in defaults {

            // ✅ Проверка на дубль для этой машины
            let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
            req.fetchLimit = 1
            req.predicate = NSPredicate(format: "car == %@ AND title == %@", car, def.title)

            let exists = ((try? context.fetch(req))?.first != nil)
            if exists { continue }

            let item = MaintenanceItem(context: context)
            item.id = UUID()
            item.title = def.title
            item.category = def.category
            item.intervalDays = Int32(def.days)

            // ✅ лучше: lastChangeMileage = текущий пробег машины
            item.lastChangeDate = Date()
            item.lastChangeMileage = car.mileage

            item.car = car

            updateNextService(for: item)
        }

        do {
            try context.save()
        } catch {
            print("❌ Failed to generate default maintenance items: \(error)")
        }
    }
}
