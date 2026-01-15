import SwiftUI
import CoreData

struct MaintenanceScheduleView: View {

    let focusItem: MaintenanceItem?
    init(focusItem: MaintenanceItem? = nil) {
        self.focusItem = focusItem
    }

    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility

    @AppStorage("avgKmPerDay") private var avgKmPerDay: Double = 40
    @AppStorage("userEmail") private var userEmail: String = ""        // ✅ NEW

    // ✅ Можно fetch-ить все items, а фильтровать по active car
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    ) private var items: FetchedResults<MaintenanceItem>

    // ✅ ВАЖНО: активная машина только текущего пользователя
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true AND ownerEmail == %@", (UserDefaults.standard.string(forKey: "userEmail") ?? "").lowercased())
    ) private var selectedCar: FetchedResults<Car>

    @State private var showAddItem = false

    @State private var quickLogItem: MaintenanceItem? = nil
    @State private var showQuickLog = false

    // MARK: - Formatting

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func formatKm(_ km: Int32) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: km)) ?? "\(km)"
    }

    private func daysUntil(_ date: Date?) -> Int {
        guard let date else { return 9999 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: today, to: due).day ?? 9999
    }

    // MARK: - Dedup / filter

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

    // ✅ Показываем только items активной машины текущего пользователя
    private var filteredItems: [MaintenanceItem] {
        guard let car = selectedCar.first else { return [] }

        // 1) только для этой машины
        let carItems = items.filter { $0.car == car }

        // 2) правила по fuelType
        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let all = allowed.isEmpty ? carItems : carItems.filter { allowed.contains($0.title ?? "") }

        return removeDuplicates(all)
    }

    // MARK: - ✅ Due mileage helpers

    private func resolvedNextMileage(for item: MaintenanceItem) -> Int32 {
        if item.nextChangeMileage > 0 { return item.nextChangeMileage }
        if item.lastChangeMileage > 0 && item.intervalKm > 0 {
            return item.lastChangeMileage + item.intervalKm
        }
        return 0
    }

    private func kmRemaining(item: MaintenanceItem, carMileage: Int32) -> Int32 {
        let due = resolvedNextMileage(for: item)
        guard due > 0 else { return 0 }
        return due - carMileage
    }

    private func estimatedMileageAtDate(carMileage: Int32, nextDate: Date?) -> Int32 {
        let d = max(0, daysUntil(nextDate))
        let est = Double(carMileage) + Double(d) * avgKmPerDay
        return Int32(est.rounded())
    }

    // MARK: - ✅ Unified urgency (DATE OR MILEAGE)

    private func unifiedUrgency(item: MaintenanceItem, carMileage: Int32) -> (color: Color, label: String) {
        let d = daysUntil(item.nextChangeDate)

        let dueMileage = resolvedNextMileage(for: item)
        let overdueByMileage = (dueMileage > 0) && (carMileage >= dueMileage)
        let overdueByDate = d < 0

        if overdueByMileage || overdueByDate {
            return (.red, "overdue")
        }

        if dueMileage > 0 {
            let remain = max(0, Int(kmRemaining(item: item, carMileage: carMileage)))
            let estDaysByKm = avgKmPerDay > 0 ? Int(ceil(Double(remain) / avgKmPerDay)) : 9999
            let effectiveDays = min(d, estDaysByKm)

            if effectiveDays == 0 { return (.orange, "today") }
            if effectiveDays <= 2 { return (.orange, "in \(effectiveDays)d") }
            if effectiveDays <= 7 { return (.yellow, "in \(effectiveDays)d") }
            return (.green, "in \(effectiveDays)d")
        }

        if d == 0 { return (.orange, "today") }
        if d <= 2 { return (.orange, "in \(d)d") }
        if d <= 7 { return (.yellow, "in \(d)d") }
        return (.green, "in \(d)d")
    }

    // MARK: - ✅ Maintenance → Service type

    private func serviceTypeForMaintenance(_ item: MaintenanceItem) -> String {
        let title = (item.title ?? "").lowercased()
        let cat = (item.category ?? "").lowercased()

        if title.contains("oil") { return "Oil" }
        if title.contains("tire") || cat.contains("tire") { return "Tires" }
        if title.contains("brake") || cat.contains("brake") { return "Brakes" }
        if title.contains("battery") || cat.contains("battery") { return "Battery" }
        if title.contains("fluid") || cat.contains("fluid") { return "Fluids" }
        if title.contains("inspect") { return "Inspection" }
        if title.contains("filter") || cat.contains("filter") { return "Inspection" }

        return "Other"
    }

    // MARK: - UI

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

                if selectedCar.first == nil {
                    Text("No car selected.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)
                } else if filteredItems.isEmpty {
                    Text("No maintenance tasks for this vehicle type.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(filteredItems) { item in
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

        // ✅ Quick Log: теперь привязан к конкретному MaintenanceItem
        .sheet(isPresented: $showQuickLog) {
            if let item = quickLogItem {
                AddServiceView(
                    prefilledType: serviceTypeForMaintenance(item),
                    prefilledMileage: selectedCar.first?.mileage ?? 0,
                    prefilledDate: Date(),
                    maintenanceItemID: item.objectID          // ✅ ВАЖНО
                )
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(tabBar)
            }
        }
    }

    private func scheduleRow(_ item: MaintenanceItem) -> some View {
        let carMileage: Int32 = selectedCar.first?.mileage ?? 0
        let u = unifiedUrgency(item: item, carMileage: carMileage)

        let dueMileage = resolvedNextMileage(for: item)
        let remainKm = kmRemaining(item: item, carMileage: carMileage)
        let estKmAtDate = estimatedMileageAtDate(carMileage: carMileage, nextDate: item.nextChangeDate)

        return HStack(alignment: .top, spacing: 12) {

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Circle().fill(u.color).frame(width: 10, height: 10)

                    Text(item.title ?? "Unknown")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text(item.category ?? "")
                        .font(.caption)
                        .foregroundColor(.cyan)
                }

                Text("Next change: \(formatDate(item.nextChangeDate))")
                    .foregroundColor(u.color == .green ? Color(hex: "#FFD54F") : u.color)
                    .font(.subheadline)

                if dueMileage > 0 {
                    Text("Due at: \(formatKm(dueMileage)) km")
                        .foregroundColor(u.color == .green ? .white.opacity(0.8) : u.color.opacity(0.95))
                        .font(.caption)

                    let txt = remainKm >= 0
                        ? "Remaining: \(formatKm(remainKm)) km"
                        : "Over by: \(formatKm(abs(remainKm))) km"

                    Text(txt)
                        .foregroundColor(u.color == .green ? .white.opacity(0.55) : u.color.opacity(0.85))
                        .font(.caption)
                }

                Text("Est. mileage (at date): \(formatKm(estKmAtDate)) km")
                    .foregroundColor(.white.opacity(0.5))
                    .font(.caption)

                if let lastDate = item.lastChangeDate {
                    Text("Last change: \(formatDate(lastDate))")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }

                HStack(spacing: 10) {
                    if item.intervalDays > 0 {
                        Text("Interval: \(item.intervalDays)d")
                            .foregroundColor(.white.opacity(0.65))
                            .font(.caption)
                    }
                    if item.intervalKm > 0 {
                        Text("• \(formatKm(item.intervalKm)) km")
                            .foregroundColor(.white.opacity(0.65))
                            .font(.caption)
                    }
                }
            }

            Spacer()

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
            .environmentObject(TabBarVisibility())
    }
}
