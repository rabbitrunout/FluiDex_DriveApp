import Foundation
import FirebaseFirestore
import CoreData

class SyncService {
    static let shared = SyncService()
    private let db = Firestore.firestore()
    
    // 📤 Отправка локальных данных в Firebase
    func syncToCloud(context: NSManagedObjectContext) {
        let fetchRequest: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        do {
            let items = try context.fetch(fetchRequest)
            for item in items {
                guard let id = item.id?.uuidString else { continue }
                
                db.collection("maintenance_schedules").document(id).setData([
                    "id": id,
                    "userId": "demo_user@example.com",
                    "title": item.title ?? "",
                    "category": item.category ?? "",
                    "intervalDays": item.intervalDays,
                    "lastChangeDate": item.lastChangeDate ?? Date(),
                    "nextChangeDate": item.nextChangeDate ?? Date(),
                    "createdAt": item.lastChangeDate ?? Date()
                ], merge: true)
            }
            print("✅ Synced local data to Firebase")
        } catch {
            print("❌ Sync error: \(error)")
        }
    }
    
    // 📥 Загрузка данных из Firebase в Core Data
    func syncFromCloud(context: NSManagedObjectContext) {
        db.collection("maintenance_schedules").getDocuments { snapshot, error in
            guard let docs = snapshot?.documents else { return }
            for doc in docs {
                let data = doc.data()
                let fetch: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", doc.documentID)
                
                if let existing = try? context.fetch(fetch).first {
                    existing.title = data["title"] as? String
                    existing.category = data["category"] as? String
                    existing.intervalDays = (data["intervalDays"] as? Int32) ?? 0
                    existing.lastChangeDate = (data["lastChangeDate"] as? Timestamp)?.dateValue()
                    existing.nextChangeDate = (data["nextChangeDate"] as? Timestamp)?.dateValue()
                } else {
                    let newItem = MaintenanceItem(context: context)
                    newItem.id = UUID(uuidString: doc.documentID)
                    newItem.title = data["title"] as? String
                    newItem.category = data["category"] as? String
                    newItem.intervalDays = (data["intervalDays"] as? Int32) ?? 0
                    newItem.lastChangeDate = (data["lastChangeDate"] as? Timestamp)?.dateValue()
                    newItem.nextChangeDate = (data["nextChangeDate"] as? Timestamp)?.dateValue()
                }
            }
            try? context.save()
            print("✅ Synced cloud data to local Core Data")
        }
    }
}
