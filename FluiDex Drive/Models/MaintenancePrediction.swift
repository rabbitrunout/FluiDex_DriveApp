import Foundation

struct MaintenancePrediction: Identifiable {
    let id: UUID = UUID()

    let type: String
    let nextDate: Date
    let nextMileage: Int32
    let confidence: Double
    let basis: String

    let lastDate: Date
    let lastMileage: Int32

    let isFallback: Bool
}
