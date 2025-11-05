import Foundation
import FirebaseFirestore
import CoreData

class SyncService {
    static let shared = SyncService()
    private let db = Firestore.firestore()
    
    // 📤 Отправка локальных данных в Firebase
    func syncToCloud(context: NSManagedObjectContext) {
        // Убедись, что сущность MaintenanceItem существует в модели Core Data
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
                    "lastChangeDate": Timestamp(date: item.lastChangeDate ?? Date()),
                    "nextChangeDate": Timestamp(date: item.nextChangeDate ?? Date()),
                    "createdAt": Timestamp(date: item.lastChangeDate ?? Date())
                ], merge: true)
            }
            print("✅ Synced local data to Firebase")
        } catch {
            print("❌ Sync error: \(error.localizedDescription)")
        }
    }
    
    // 📥 Загрузка данных из Firebase в Core Data
    func syncFromCloud(context: NSManagedObjectContext) {
        db.collection("maintenance_schedules").getDocuments(completion: { snapshot, error in
            if let error = error {
                print("❌ Firestore download error: \(error.localizedDescription)")
                return
            }
            
            guard let docs = snapshot?.documents else { return }
            
            for doc in docs {
                let data = doc.data()
                let fetch: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
                fetch.predicate = NSPredicate(format: "id == %@", doc.documentID)
                
                let existing = try? context.fetch(fetch).first
                let item = existing ?? MaintenanceItem(context: context)
                
                item.id = UUID(uuidString: doc.documentID)
                item.title = data["title"] as? String
                item.category = data["category"] as? String
                item.intervalDays = (data["intervalDays"] as? Int32) ?? 0
                item.lastChangeDate = (data["lastChangeDate"] as? Timestamp)?.dateValue()
                item.nextChangeDate = (data["nextChangeDate"] as? Timestamp)?.dateValue()
            }
            
            do {
                try context.save()
                print("✅ Synced cloud data to local Core Data")
            } catch {
                print("❌ Failed to save Core Data after sync: \(error.localizedDescription)")
            }
        })
    }
}
