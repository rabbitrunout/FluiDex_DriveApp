import SwiftUI
import CoreData

@main
struct FluiDex_DriveApp: App {
    @StateObject var tabBar = TabBarVisibility()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
                .environmentObject(tabBar)
        }
    }
}
