import CoreData

final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "FluiDex_Drive")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        let description = container.persistentStoreDescriptions.first
        description?.shouldMigrateStoreAutomatically = true
        description?.shouldInferMappingModelAutomatically = true
        let storeURL = description?.url

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("⚠️ Core Data load error: \(error.localizedDescription)")

                if error.code == 134140 {
                    if let storeURL = storeURL {
                        do {
                            let coordinator = self.container.persistentStoreCoordinator
                            if let store = coordinator.persistentStores.first {
                                try coordinator.remove(store)
                                print("🔒 Persistent store detached.")
                            }

                            // 💤 Небольшая пауза, чтобы система освободила файлы
                            DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                                do {
                                    let fm = FileManager.default
                                    for ext in ["", "shm", "wal"] {
                                        let file = ext.isEmpty ? storeURL : storeURL.appendingPathExtension(ext)
                                        if fm.fileExists(atPath: file.path) {
                                            try fm.removeItem(at: file)
                                            print("🗑️ Removed: \(file.lastPathComponent)")
                                        }
                                    }

                                    // ♻️ Пересоздание хранилища
                                    DispatchQueue.main.async {
                                        self.container.loadPersistentStores { _, reloadError in
                                            if let reloadError = reloadError {
                                                fatalError("💥 Failed to reload Core Data: \(reloadError)")
                                            } else {
                                                print("✅ Core Data successfully reset and reloaded.")
                                            }
                                        }
                                    }
                                } catch {
                                    fatalError("💥 Failed to clean up corrupted store after delay: \(error)")
                                }
                            }

                        } catch {
                            fatalError("💥 Failed to remove corrupted store: \(error)")
                        }
                    }
                } else {
                    fatalError("💥 Unresolved error \(error), \(error.userInfo)")
                }
            } else {
                print("✅ Core Data store loaded successfully.")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
