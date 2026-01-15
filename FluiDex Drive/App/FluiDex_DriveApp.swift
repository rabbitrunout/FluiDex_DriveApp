import SwiftUI
import CoreData
import Firebase
import UserNotifications

@main
struct FluiDex_DriveApp: App {
    init() {
            NotificationManager.shared.requestPermission()
        }
    let persistenceController = PersistenceController.shared
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @AppStorage("hasSelectedCar") private var hasSelectedCar: Bool = false
    
    var body: some Scene {
        WindowGroup {
            AppEntryView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // 🚀 Инициализация Firebase
                    FirebaseApp.configure()
                    
                    // 🔔 Запрос разрешения на уведомления (наш менеджер)
                    NotificationManager.shared.requestPermission()
                    
                    // ☁️ Синхронизация с Firebase при старте
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        SyncService.shared.syncFromCloud(context: persistenceController.container.viewContext)
                    }
                }
                // 🔁 Автоматическая проверка входа
                .onChange(of: isLoggedIn) { oldValue, newValue in
                    if !newValue {
                        hasSelectedCar = false
                    }
                }
        }
    }
}
