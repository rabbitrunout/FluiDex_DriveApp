import Foundation
import UserNotifications
import CoreData

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    /// 🚀 Запросить разрешение (старый метод — оставим)
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if success {
                print("✅ Notifications authorized")
            } else if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            }
        }
    }

    /// ✅ Новый: запрос с completion (удобно для UI)
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion(granted) }
        }
    }

    /// ✅ Новый: получить статус разрешения
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - MaintenanceItem reminders (твои методы)

    /// 🗓 Запланировать уведомления для MaintenanceItem
    func scheduleNotifications(for item: MaintenanceItem) {
        guard let title = item.title, let date = item.nextChangeDate else { return }

        let intervals: [(String, Int)] = [
            ("in 7 days", 7),
            ("in 3 days", 3),
            ("today", 0)
        ]

        for (label, daysBefore) in intervals {
            let content = UNMutableNotificationContent()
            content.title = "Service Reminder: \(title)"
            content.body = daysBefore == 0
                ? "It's time to service your car: \(title)."
                : "Upcoming maintenance for \(title) is due \(label)."
            content.sound = .default

            // ✅ Ставим на 09:00, чтобы не прилетало ночью
            if let base = Calendar.current.date(byAdding: .day, value: -daysBefore, to: date),
               base > Date() {

                var comps = Calendar.current.dateComponents([.year, .month, .day], from: base)
                comps.hour = 9
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(item.id ?? UUID())_\(daysBefore)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    /// ❌ Очистить уведомления, если запись удалена
    func removeNotifications(for item: MaintenanceItem) {
        guard let id = item.id else { return }
        let ids = ["\(id)_7", "\(id)_3", "\(id)_0"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// ✅ NEW: отмена и пересоздание уведомлений (когда ты обновил nextChangeDate)
    func rescheduleNotifications(for item: MaintenanceItem) {
        removeNotifications(for: item)
        scheduleNotifications(for: item)
    }

    // MARK: - ✅ AI Prediction reminders (НОВОЕ)

    /// Ставит напоминания по AI-прогнозам (7/3/0 дней) для машины.
    /// carID лучше передавать стабильный: car.objectID.uriRepresentation().absoluteString
    func schedulePredictionReminders(
        carName: String,
        carID: String,
        predictions: [MaintenancePrediction],
        dayOffsets: [Int] = [7, 3, 0]
    ) {
        let center = UNUserNotificationCenter.current()

        for pred in predictions {
            for offset in dayOffsets {
                guard let fire = Calendar.current.date(byAdding: .day, value: -offset, to: pred.nextDate) else { continue }
                if fire <= Date() { continue }

                let content = UNMutableNotificationContent()
                content.title = "\(carName): \(pred.type) reminder"
                content.sound = .default

                let whenText = (offset == 0) ? "Today" : "In \(offset) day(s)"
                content.body = "\(whenText). Predicted next: \(formatDate(pred.nextDate)) • ≈ \(pred.nextMileage) km"

                var comps = Calendar.current.dateComponents([.year, .month, .day], from: fire)
                comps.hour = 9
                comps.minute = 0

                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

                let id = predictionNotificationID(carID: carID, type: pred.type, offsetDays: offset)
                let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(req)
            }
        }
    }

    /// Отменить все AI-prediction уведомления для машины
    func cancelPredictionReminders(carID: String) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { reqs in
            let ids = reqs.map(\.identifier).filter { $0.hasPrefix("pred:\(carID):") }
            center.removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Debug

    /// 🕵️ Проверить запланированные уведомления (старое — оставим)
    func listPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("🔔 Pending notifications: \(requests.count)")
            for req in requests {
                print("• \(req.identifier): \(req.content.title) — \(req.content.body)")
            }
        }
    }

    // MARK: - Helpers

    private func predictionNotificationID(carID: String, type: String, offsetDays: Int) -> String {
        "pred:\(carID):\(type.lowercased()):\(offsetDays)"
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}
