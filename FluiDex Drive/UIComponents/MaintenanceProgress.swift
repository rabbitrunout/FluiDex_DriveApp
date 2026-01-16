import Foundation

enum MaintenanceProgress {

    // MARK: - Basics

    static func clamp01(_ x: Double) -> Double {
        min(max(x, 0), 1)
    }

    static func byMileage(current: Int32, last: Int32, next: Int32) -> Double {
        let total = Double(max(next - last, 1))
        let used  = Double(current - last)
        return clamp01(used / total)
    }

    static func byDate(now: Date, last: Date, next: Date) -> Double {
        let total = max(next.timeIntervalSince(last), 1)
        let used  = now.timeIntervalSince(last)
        return clamp01(used / total)
    }

    // MARK: - Combined progress (0...1)

    /// 0...1: how close to due (higher = closer)
    static func combined(carMileage: Int32, now: Date, p: MaintenancePrediction) -> Double {
        // If next mileage isn't meaningful (e.g. 0 interval types), use only date progress
        let hasMileage = p.nextMileage > p.lastMileage

        let kmP = hasMileage ? byMileage(current: carMileage, last: p.lastMileage, next: p.nextMileage) : 0
        let dtP = byDate(now: now, last: p.lastDate, next: p.nextDate)

        if !hasMileage { return dtP }
        return clamp01((kmP + dtP) / 2.0)
    }

    // MARK: - Overdue

    /// True if already past due by date or mileage (for non-fallback predictions)
    static func isOverdue(carMileage: Int32, now: Date, p: MaintenancePrediction) -> Bool {
        if p.isFallback { return false }
        if now > p.nextDate { return true }
        if p.nextMileage > 0 && carMileage >= p.nextMileage { return true }
        return false
    }

    // MARK: - Status helper

    enum Status: Equatable {
        case estimate        // fallback
        case normal          // ok
        case dueSoon         // close to due (>= 85%)
        case overdue         // already due
    }

    static func status(carMileage: Int32, now: Date, p: MaintenancePrediction) -> Status {
        if p.isFallback { return .estimate }
        if isOverdue(carMileage: carMileage, now: now, p: p) { return .overdue }

        let prog = combined(carMileage: carMileage, now: now, p: p)
        if prog >= 0.85 { return .dueSoon }

        return .normal
    }
}
