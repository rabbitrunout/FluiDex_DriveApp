//
//  FluiDex_DriveApp.swift
//  FluiDex Drive
//
//  Created by Irina Saf on 2025-09-26.
//

import SwiftUI
import CoreData

@main
struct FluiDex_DriveApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
