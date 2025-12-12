import Foundation

struct MaintenanceRules {

    // какие задачи разрешены для каждого типа топлива
    static func allowedTasks(for fuelType: String) -> [String] {

        switch fuelType.lowercased() {

        case "gasoline", "petrol", "gas":
            return [
                "Engine Oil",
                "Air Filter",
                "Cabin Filter",
                "Tire Rotation",
                "Brake Fluid",
                "Coolant",
                "Battery Check",
                "Transmission Fluid",
                "Inspection"
            ]

        case "diesel":
            return [
                "Engine Oil",
                "Fuel Filter",
                "Air Filter",
                "Cabin Filter",
                "Tire Rotation",
                "Coolant",
                "Battery Check",
                "Brake Fluid",
                "Inspection"
            ]

        case "hybrid":
            return [
                "Engine Oil",
                "Air Filter",
                "Cabin Filter",
                "Coolant",
                "Battery Check",
                "Brake Fluid",
                "Tire Rotation",
                "Hybrid System Check",
                "Inspection"
            ]

        case "electric":
            return [
                "Battery Check",
                "Coolant",
                "Brake Fluid",
                "Tire Rotation",
                "HV System Check",
                "Inspection"
            ]

        default:
            return []
        }
    }
}
