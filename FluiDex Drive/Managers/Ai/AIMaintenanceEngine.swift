import Foundation
import CoreData

class AIMaintenanceEngine {
    static let shared = AIMaintenanceEngine()

    func predictNextMaintenance(for car: Car, using records: [ServiceRecord]) -> [MaintenancePrediction] {
        var predictions: [MaintenancePrediction] = []

        let types = Set(records.compactMap { $0.type })
        for type in types {
            let filtered = records.filter { $0.type == type }.sorted { $0.date ?? .distantPast < $1.date ?? .distantPast }
            guard filtered.count >= 2 else { continue }

            let avgMileageDiff = zip(filtered, filtered.dropFirst())
                .map { later, earlier in later.mileage - earlier.mileage }
                .reduce(0, +) / Int32(filtered.count - 1)

            let avgTimeDiff = zip(filtered, filtered.dropFirst())
                .map { later, earlier in
                    Calendar.current.dateComponents([.day], from: earlier.date ?? .distantPast, to: later.date ?? .distantPast).day ?? 0
                }
                .reduce(0, +) / (filtered.count - 1)


            if let last = filtered.last?.date {
                let nextDate = Calendar.current.date(byAdding: .day, value: avgTimeDiff, to: last) ?? Date()
                let nextMileage = filtered.last!.mileage + avgMileageDiff
                predictions.append(MaintenancePrediction(type: type, nextDate: nextDate, nextMileage: nextMileage))
            }
        }
        return predictions
    }
}

struct MaintenancePrediction: Identifiable {
    let id = UUID()
    let type: String
    let nextDate: Date
    let nextMileage: Int32
}
