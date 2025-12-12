import Foundation

func filterTasksByFuel(_ items: [MaintenanceItem], for car: Car) -> [MaintenanceItem] {
    guard let type = car.fuelType else { return items }

    let allowed = MaintenanceRules.allowedTasks(for: type.lowercased())

    return items.filter { item in
        allowed.contains(item.title ?? "")
    }
}
