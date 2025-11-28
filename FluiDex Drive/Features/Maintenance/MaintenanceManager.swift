import Foundation
import CoreData

class MaintenanceManager {
    static let shared = MaintenanceManager()
    
    func updateNextService(for item: MaintenanceItem, in context: NSManagedObjectContext) {
        let calendar = Calendar.current
        item.nextChangeDate = calendar.date(
            byAdding: .day,
            value: Int(item.intervalDays),
            to: item.lastChangeDate ?? Date()
        )
        do { try context.save() }
        catch { print("❌ Failed to update nextChangeDate: \(error)") }
    }
    
    func generateDefaultItems(for car: Car, in context: NSManagedObjectContext) {
        let defaults: [(String, String, Int)] = [
            ("Engine Oil", "Fluids", 180),
            ("Brake Fluid", "Fluids", 365),
            ("Coolant", "Fluids", 365),
            ("Air Filter", "Filters", 180),
            ("Cabin Filter", "Filters", 180),
            ("Transmission Fluid", "Fluids", 730),
            ("Tire Rotation", "Tires", 180),
            ("Battery Check", "Electrical", 365)
        ]
        for (title, category, days) in defaults {
            let item = MaintenanceItem(context: context)
            item.id = UUID()
            item.title = title
            item.category = category
            item.intervalDays = Int32(days)
            item.lastChangeDate = Date()
            item.car = car
            updateNextService(for: item, in: context)
        }
    }
}
