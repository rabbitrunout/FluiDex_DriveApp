import SwiftUI
import CoreData

struct MaintenanceScheduleView: View {
    
    let focusItem: MaintenanceItem?

    init(focusItem: MaintenanceItem? = nil) {
        self.focusItem = focusItem
    }

    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    ) private var items: FetchedResults<MaintenanceItem>

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    ) private var selectedCar: FetchedResults<Car>

    @State private var showAddItem = false

    // ✅ quick log
    @State private var quickLogItem: MaintenanceItem? = nil
    @State private var showQuickLog = false

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func removeDuplicates(_ list: [MaintenanceItem]) -> [MaintenanceItem] {
        var unique: [String: MaintenanceItem] = [:]
        for item in list {
            guard let title = item.title else { continue }
            if let existing = unique[title] {
                if let d1 = item.nextChangeDate, let d2 = existing.nextChangeDate, d1 < d2 {
                    unique[title] = item
                }
            } else {
                unique[title] = item
            }
        }
        return Array(unique.values)
            .sorted { ($0.nextChangeDate ?? .distantFuture) < ($1.nextChangeDate ?? .distantFuture) }
    }

    private var filteredItems: [MaintenanceItem] {
        guard let car = selectedCar.first else { return Array(items) }

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let all = allowed.isEmpty ? Array(items) : items.filter { allowed.contains($0.title ?? "") }
        return removeDuplicates(all)
    }

    // ✅ ЕДИНАЯ ЛОГИКА СРОЧНОСТИ (фикс: сравнение по startOfDay)
    private func unifiedUrgency(for date: Date?) -> (color: Color, label: String) {
        guard let date else { return (.gray, "—") }

        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: date)
        let days = cal.dateComponents([.day], from: today, to: due).day ?? 999

        if days < 0 { return (.red, "overdue") }
        if days == 0 { return (.orange, "today") }
        if days <= 2 { return (.orange, "in \(days)d") }
        if days <= 7 { return (.yellow, "in \(days)d") }
        return (.green, "in \(days)d") // дальше недели — зелёный
    }

    // ✅ маппинг Maintenance → тип сервиса для AddServiceView
    private func serviceTypeForMaintenance(_ item: MaintenanceItem) -> String {
        let title = (item.title ?? "").lowercased()
        let cat = (item.category ?? "").lowercased()

        if title.contains("oil") || cat.contains("fluid") { return "Oil" }
        if title.contains("tire") || cat.contains("tire") { return "Tires" }
        if title.contains("brake") || cat.contains("brake") { return "Brakes" }
        if title.contains("battery") || cat.contains("battery") { return "Battery" }
        if title.contains("inspect") { return "Inspection" }
        if cat.contains("filter") || title.contains("filter") { return "Inspection" }

        return "Other"
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Maintenance Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .padding(.top, 40)

                if filteredItems.isEmpty {
                    Text("No maintenance tasks for this vehicle type.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(filteredItems) { item in
                                // ✅ карточка кликабельная → быстрый лог сервиса
                                Button {
                                    quickLogItem = item
                                    showQuickLog = true
                                } label: {
                                    scheduleRow(item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }

                Spacer()

                NeonButton(title: "Add Maintenance Task") {
                    showAddItem = true
                }
                .sheet(isPresented: $showAddItem) {
                    AddMaintenanceItemView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)

        // ✅ Быстрый AddService с предзаполнением
        .sheet(isPresented: $showQuickLog) {
            AddServiceView(
                prefilledType: serviceTypeForMaintenance(quickLogItem ?? MaintenanceItem()),
                prefilledMileage: selectedCar.first?.mileage ?? 0,
                prefilledDate: Date()
            )
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(TabBarVisibility())
        }
    }

    private func scheduleRow(_ item: MaintenanceItem) -> some View {
        let u = unifiedUrgency(for: item.nextChangeDate)

        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(u.color)
                        .frame(width: 10, height: 10)

                    Text(item.title ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(item.category ?? "")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }

                Text("Next change: \(formatDate(item.nextChangeDate))")
                    .foregroundColor(u.color == .green ? Color(hex: "#FFD54F") : u.color) // ✅ если просрочено — красным
                    .font(.subheadline)

                if let lastDate = item.lastChangeDate {
                    Text("Last change: \(formatDate(lastDate))")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }

                Text("Interval: \(item.intervalDays) days")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }
            Spacer()

            // ✅ маленький бейдж справа (overdue / in 3d)
            Text(u.label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(u.color.opacity(0.35), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .shadow(color: u.color.opacity(0.18), radius: 6)
        .padding(.horizontal, 16)
    }
}

#Preview {
    NavigationStack {
        MaintenanceScheduleView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
