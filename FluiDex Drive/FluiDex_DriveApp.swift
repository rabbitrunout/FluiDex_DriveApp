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
    @StateObject private var serviceVM = ServiceViewModel()
    
    var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(serviceVM) // пробрасываем во все экраны
            }
        }
    }
