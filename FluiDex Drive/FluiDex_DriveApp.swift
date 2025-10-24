import SwiftUI
import CoreData

@main
struct FluiDex_DriveApp: App {
    @StateObject private var tabBar = TabBarVisibility()
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(tabBar)
        }
        // 💾 Централизованное сохранение Core Data
        .onChange(of: scenePhase) { phase in
            handleSceneChange(phase)
        }
    }

    // MARK: - Сохранение контекста
    private func handleSceneChange(_ phase: ScenePhase) {
        let context = persistenceController.container.viewContext
        switch phase {
        case .background, .inactive:
            saveContext(context)
        default:
            break
        }
    }

    private func saveContext(_ context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Context successfully saved in background")
            } catch {
                print("❌ Error saving context in background: \(error.localizedDescription)")
            }
        }
    }
}
