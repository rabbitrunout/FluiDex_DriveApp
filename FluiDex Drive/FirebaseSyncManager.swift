import Foundation
import FirebaseFirestore
import Firebase
import Combine   // ✅ добавь
import CoreData

final class FirebaseSyncManager {
    private let db = Firestore.firestore()
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // 🚀 Сохранение записи в Firestore
    func syncServiceRecord(_ record: ServiceRecord) {
        guard let userEmail = UserDefaults.standard.string(forKey: "userEmail"),
              !userEmail.isEmpty else {
            print("⚠️ No userEmail in UserDefaults — skip sync")
            return
        }

        let data: [String: Any] = [
            "userEmail": userEmail,
            "type": record.type ?? "",
            "mileage": Int(record.mileage),
            "note": record.note ?? "",
            "totalCost": record.totalCost,            // если есть это поле
            "date": record.date ?? Date(),
            "nextServiceKm": Int(record.nextServiceKm),
            "nextServiceDate": record.nextServiceDate ?? Date(),
            "carName": record.car?.name ?? ""
        ]

        db.collection("serviceRecords").addDocument(data: data) { error in
            if let error = error {
                print("❌ Firestore sync failed: \(error.localizedDescription)")
            } else {
                print("✅ Synced record to Firestore")
            }
        }
    }

    // 📥 Загрузка записей пользователя
    func loadServiceRecords(for userEmail: String, completion: @escaping () -> Void) {
        db.collection("serviceRecords")
            .whereField("userEmail", isEqualTo: userEmail)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Firestore fetch failed: \(error.localizedDescription)")
                    completion()
                    return
                }

                self.context.perform {
                    for doc in snapshot?.documents ?? [] {
                        let data = doc.data()
                        let rec = ServiceRecord(context: self.context)
                        rec.id = UUID()
                        rec.type = data["type"] as? String
                        rec.mileage = Int32(data["mileage"] as? Int ?? 0)
                        rec.note = data["note"] as? String
                        rec.totalCost = data["totalCost"] as? Double ?? 0
                        if let ts = data["date"] as? Timestamp { rec.date = ts.dateValue() }
                        rec.nextServiceKm = Int32(data["nextServiceKm"] as? Int ?? 0)
                        if let ts2 = data["nextServiceDate"] as? Timestamp { rec.nextServiceDate = ts2.dateValue() }
                        // при желании можно проставить связь с активной машиной/юзером
                    }
                    do { try self.context.save() } catch {
                        print("⚠️ Save after fetch failed: \(error)")
                    }
                    completion()
                }
            }
    }
}
