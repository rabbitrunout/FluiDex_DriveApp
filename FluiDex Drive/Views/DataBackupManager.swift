import Foundation
import CoreData

final class DataBackupManager {
    static let shared = DataBackupManager()

    private init() {}

    // MARK: - 📤 Экспорт в JSON
    func exportData(from context: NSManagedObjectContext) -> URL? {
        let entities = context.persistentStoreCoordinator?.managedObjectModel.entities ?? []
        var exportDict: [String: [[String: Any]]] = [:]

        for entity in entities {
            guard let name = entity.name else { continue }
            let request = NSFetchRequest<NSManagedObject>(entityName: name)
            do {
                let objects = try context.fetch(request)
                let array = objects.map { $0.toDictionary() }
                exportDict[name] = array
            } catch {
                print("⚠️ Error fetching \(name): \(error)")
            }
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportDict, options: [.prettyPrinted])
            let fileURL = getBackupURL()
            try jsonData.write(to: fileURL)
            print("✅ Backup saved at: \(fileURL)")
            return fileURL
        } catch {
            print("❌ Failed to export data: \(error)")
            return nil
        }
    }

    // MARK: - 📥 Импорт из JSON
    func importData(to context: NSManagedObjectContext) {
        let fileURL = getBackupURL()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ No backup file found")
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: [[String: Any]]] else { return }

            for (entityName, objects) in json {
                for objectData in objects {
                    let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
                    for (key, value) in objectData {
                        entity.setValue(value is NSNull ? nil : value, forKey: key)
                    }
                }
            }

            try context.save()
            print("✅ Data restored from backup.")
        } catch {
            print("❌ Failed to import data: \(error)")
        }
    }

    // MARK: - 🔗 Вспомогательные
    private func getBackupURL() -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent("FluiDex_Backup.json")
    }
}

// MARK: - 🔧 Расширение для сериализации NSManagedObject
extension NSManagedObject {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        for attribute in entity.attributesByName {
            let key = attribute.key
            let value = value(forKey: key)
            dict[key] = value ?? NSNull()
        }
        return dict
    }
}
