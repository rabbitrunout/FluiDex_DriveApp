import Foundation
import Combine

class ServiceViewModel: ObservableObject {
    @Published var services: [Service] = []
    
    init() {
        services = [
            Service(type: "Oil Change", date: Date(), mileage: 85200, cost: 95.0),
            Service(type: "Tire Rotation", date: Date().addingTimeInterval(-86400 * 30), mileage: 84000, cost: 60.0),
            Service(type: "Brake Fluid", date: Date().addingTimeInterval(-86400 * 90), mileage: 82000, cost: 120.0)
        ]
    }
    
    func addService(type: String, date: Date, mileage: Int, cost: Double) {
        let newService = Service(type: type, date: date, mileage: mileage, cost: cost)
        services.append(newService)
    }
    
    /// Возвращает прогресс (0.0 – 1.0) для определённого типа сервиса
    func progress(for type: String, currentMileage: Int) -> Double {
        let interval: Int
        
        switch type {
        case "Oil":
            interval = 10000
        case "Coolant":
            interval = 30000
        case "Brake":
            interval = 40000
        default:
            interval = 10000
        }
        
        // Находим последнюю запись этого типа
        let lastService = services.last { $0.type.contains(type) }
        let lastMileage = lastService?.mileage ?? 0
        
        let distanceSince = currentMileage - lastMileage
        let progress = 1.0 - min(Double(distanceSince) / Double(interval), 1.0)
        
        return progress
    }
}
