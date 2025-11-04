import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    static let shared = NotificationManager()

    // 🚀 Запросить разрешение
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, error in
            if success {
                print("✅ Notifications authorized")
            } else if let error = error {
                print("❌ Notification error: \(error.localizedDescription)")
            }
        }
    }

    // 🗓 Запланировать уведомления для MaintenanceItem
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

            if let triggerDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: date),
               triggerDate > Date() {
                let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(identifier: "\(item.id ?? UUID())_\(daysBefore)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    // ❌ Очистить уведомления, если запись удалена
    func removeNotifications(for item: MaintenanceItem) {
        guard let id = item.id else { return }
        let ids = ["\(id)_7", "\(id)_3", "\(id)_0"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
