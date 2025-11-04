//
//  AddMaintenanceItemView.swift
//  FluiDex Drive
//
//  Created by Irina Saf on 2025-11-04.
//

import SwiftUI
import CoreData

struct AddMaintenanceItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var category = "Fluids"
    @State private var intervalDays: Double = 180
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Text("Add Maintenance Item")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .glow(color: .cyan, radius: 8)
                
                glowingField("Item Name", text: $title, icon: "wrench.and.screwdriver.fill")
                
                glowingPicker("Category", selection: $category,
                              options: ["Fluids","Filters","Tires","Electrical","Other"],
                              icon: "folder.fill")
                
                VStack(alignment: .leading) {
                    Text("Interval: \(Int(intervalDays)) days")
                        .foregroundColor(.white)
                    Slider(value: $intervalDays, in: 30...730, step: 30)
                        .tint(.cyan)
                }.padding(.horizontal)
                
                NeonButton(title: "Save") {
                    let newItem = MaintenanceItem(context: viewContext)
                    newItem.id = UUID()
                    newItem.title = title
                    newItem.category = category
                    newItem.intervalDays = Int32(intervalDays)
                    newItem.lastChangeDate = Date()
                    MaintenanceManager.shared.updateNextService(for: newItem, in: viewContext)

                    // 🔔 Добавляем уведомления
                    NotificationManager.shared.scheduleNotifications(for: newItem)

                    dismiss()
                }

                
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}


#Preview {
    AddMaintenanceItemView()
}
