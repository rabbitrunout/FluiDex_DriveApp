import Foundation
import CoreData

final class AIMaintenanceEngine {
    static let shared = AIMaintenanceEngine()
    private init() {}

    /// Predicts next maintenance ONLY for the given car.
    /// Important: `records` may contain records for many cars — we filter by car.objectID here.
    func predictNextMaintenance(for car: Car, using records: [ServiceRecord]) -> [MaintenancePrediction] {

        // ✅ FIX: strict filtering by car (objectID is reliable across contexts)
        let carID = car.objectID
        let carRecords = records.filter { $0.car?.objectID == carID }

        let grouped = Dictionary(grouping: carRecords, by: { normalizeType($0.type ?? "Other") })

        let targetTypes: [String] = ["Oil", "Brakes", "Battery", "Tires", "Fluids", "Inspection"]

        var predictions: [MaintenancePrediction] = []

        for type in targetTypes {
            let list = (grouped[type] ?? [])
                .filter { $0.date != nil }
                .sorted { (a: ServiceRecord, b: ServiceRecord) -> Bool in
                    (a.date ?? .distantPast) > (b.date ?? .distantPast)
                }

            if let p = predict(for: type, car: car, history: list) {
                predictions.append(p)
            }
        }

        predictions.sort { $0.nextDate < $1.nextDate }
        return predictions
    }

    // MARK: - Per-type prediction

    private func predict(for type: String, car: Car, history: [ServiceRecord]) -> MaintenancePrediction? {

        guard let last = history.first else {
            return fallbackPrediction(type: type, car: car)
        }

        let lastDate = last.date ?? Date()
        let lastMileage = last.mileage

        if history.count >= 2 {
            let second = history[1]
            let prevDate = second.date ?? lastDate
            let prevMileage = second.mileage

            let deltaDays = Swift.max(1, daysBetween(prevDate, lastDate))
            let deltaKm = Swift.max(1, Int(lastMileage - prevMileage))

            let kmPerDay = Double(deltaKm) / Double(deltaDays)
            let (defaultKm, defaultDays) = defaultInterval(for: type)

            // If driving is extremely low, fallback to default intervals
            if kmPerDay < 1 {
                return fallbackPrediction(type: type, car: car, lastDate: lastDate, lastMileage: lastMileage)
            }

            // If defaultKm == 0 (Battery/Inspection) rely on days
            let daysToKm = (defaultKm > 0) ? Int(ceil(Double(defaultKm) / kmPerDay)) : defaultDays
            let predictedDateByKm = Calendar.current.date(byAdding: .day, value: daysToKm, to: lastDate) ?? lastDate
            let predictedByDays = Calendar.current.date(byAdding: .day, value: defaultDays, to: lastDate) ?? lastDate

            let nextDate = earlierDate(predictedDateByKm, predictedByDays)

            let daysToNext = Swift.max(0, daysBetween(Date(), nextDate))
            let estMileage = Double(car.mileage) + Double(daysToNext) * kmPerDay
            let nextMileage = Int32(estMileage.rounded())

            let conf = Swift.min(0.95, Swift.max(0.55, Double(history.count) / 6.0))

            return MaintenancePrediction(
                type: type,
                nextDate: nextDate,
                nextMileage: Swift.max(nextMileage, car.mileage),
                confidence: conf,
                basis: "history",
                lastDate: lastDate,
                lastMileage: lastMileage,
                isFallback: false
            )
        }

        return fallbackPrediction(type: type, car: car, lastDate: lastDate, lastMileage: lastMileage)
    }

    // MARK: - Defaults / fallback

    private func fallbackPrediction(type: String, car: Car, lastDate: Date? = nil, lastMileage: Int32? = nil) -> MaintenancePrediction? {
        let (km, days) = defaultInterval(for: type)

        let baseDate = lastDate ?? Date()
        let nextDate = Calendar.current.date(byAdding: .day, value: days, to: baseDate) ?? baseDate

        let baseMileage = lastMileage ?? car.mileage
        let nextMileage = baseMileage + Int32(km)

        return MaintenancePrediction(
            type: type,
            nextDate: nextDate,
            nextMileage: Swift.max(nextMileage, car.mileage),
            confidence: lastDate == nil ? 0.35 : 0.45,
            basis: "fallback",
            lastDate: baseDate,
            lastMileage: baseMileage,
            isFallback: true
        )
    }

    private func defaultInterval(for type: String) -> (km: Int, days: Int) {
        switch type {
        case "Oil": return (8000, 180)
        case "Brakes": return (30000, 365)
        case "Battery": return (0, 730)
        case "Tires": return (10000, 180)
        case "Fluids": return (20000, 365)
        case "Inspection": return (0, 365)
        default: return (10000, 180)
        }
    }

    private func normalizeType(_ raw: String) -> String {
        let t = raw.lowercased()
        if t.contains("oil") { return "Oil" }
        if t.contains("brake") { return "Brakes" }
        if t.contains("battery") { return "Battery" }
        if t.contains("tire") { return "Tires" }
        if t.contains("fluid") { return "Fluids" }
        if t.contains("inspect") || t.contains("filter") { return "Inspection" }
        return "Other"
    }

    private func daysBetween(_ a: Date, _ b: Date) -> Int {
        let cal = Calendar.current
        let d1 = cal.startOfDay(for: a)
        let d2 = cal.startOfDay(for: b)
        return cal.dateComponents([.day], from: d1, to: d2).day ?? 0
    }

    private func earlierDate(_ a: Date, _ b: Date) -> Date {
        (a <= b) ? a : b
    }
}
