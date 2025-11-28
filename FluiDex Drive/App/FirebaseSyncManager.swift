import Foundation
import FirebaseFirestore
import CoreData

final class FirebaseSyncManager {
    
    // 🔥 Singleton
    static let shared = FirebaseSyncManager(context:
        PersistenceController.shared.container.viewContext
    )

    private let db = Firestore.firestore()
    private let context: NSManagedObjectContext

    // Текущий пользователь
    var currentUserId: String? {
        UserDefaults.standard.string(forKey: "userEmail")
    }

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: — ▶️ Синхронизация поездки
    func syncTrip(_ trip: Trip, car: Car) {
        guard let userId = currentUserId,
              let carId = car.id?.uuidString,
              let tripId = trip.id?.uuidString else { return }

        let data: [String: Any] = [
            "id": tripId,
            "date": trip.date ?? Date(),
            "distance": trip.distance,
            "carId": carId
        ]

        db.collection("users")
            .document(userId)
            .collection("cars")
            .document(carId)
            .collection("trips")
            .document(tripId)
            .setData(data) { error in
                if let error = error {
                    print("❌ Firebase trip sync failed: \(error)")
                } else {
                    print("☁️ Trip synced to Firebase")
                }
            }
    }

    
    // MARK: - 🔵 Sync Trip
    func syncTrip(_ trip: Trip, for car: Car) {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              let carId = car.id?.uuidString else { return }

        let data: [String: Any] = [
            "id": trip.id?.uuidString ?? "",
            "date": trip.date ?? Date(),
            "distance_meters": trip.distance,
            "carId": carId,
            "userEmail": userEmail
        ]

        db.collection("tripRecords")
            .addDocument(data: data) { error in
                if let error = error {
                    print("🔥 Trip sync failed: \(error)")
                } else {
                    print("☁️ Trip synced to Firebase!")
                }
            }
    }

    // MARK: - 🔧 Sync Updated Car Mileage
    func syncCarMileage(_ car: Car) {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              let carId = car.id?.uuidString else { return }

        db.collection("cars")
            .document(carId)
            .setData([
                "mileage": car.mileage,
                "userEmail": userEmail
            ], merge: true)
    }
    
    func syncServiceRecord(_ record: ServiceRecord) {
            // 💾 Тут будет логика отправки в Firebase (когда будешь готова)
            // Пока оставим заглушку с логом
            print("☁️ Syncing ServiceRecord to Firebase: id=\(record.id?.uuidString ?? "nil") type=\(record.type ?? "Unknown")")
        }

}
