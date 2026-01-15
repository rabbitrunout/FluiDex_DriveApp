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
    @AppStorage("userEmail") private var userEmail: String = ""

    // ✅ Fetch all items, filter locally by selectedCar
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    ) private var items: FetchedResults<MaintenanceItem>

    // ✅ Fetch all cars once
    @FetchRequest(sortDescriptors: [], animation: .easeInOut)
    private var allCars: FetchedResults<Car>

    @State private var showAddItem = false
    @State private var showSelectCar = false

    // ✅ ONLY THIS (no showQuickLog boolean!)
    @State private var quickLogItem: MaintenanceItem? = nil

    @State private var searchText: String = ""
    @State private var refreshID = UUID()

    enum Filter: String, CaseIterable {
        case all = "All"
        case urgent = "Urgent"
        case upcoming = "Upcoming"
        case overdue = "Overdue"
    }
    @State private var filter: Filter = .all

    // MARK: - Formatters (perf)
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    private static let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf
    }()

    private var owner: String {
        userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // ✅ Active car for current user (dynamic)
    private var selectedCar: Car? {
        guard !owner.isEmpty else { return nil }
        return allCars.first(where: { ($0.ownerEmail ?? "").lowercased() == owner && $0.isSelected })
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        return Self.dateFormatter.string(from: date)
    }

    private func formatKm(_ km: Int32) -> String {
        Self.numberFormatter.string(from: NSNumber(value: km)) ?? "\(km)"
    }

    private func daysUntil(_ date: Date?) -> Int {
        guard let date else { return 9999 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: today, to: due).day ?? 9999
    }

    private func removeDuplicates(_ list: [MaintenanceItem]) -> [MaintenanceItem] {
        var unique: [String: MaintenanceItem] = [:]
        for item in list {
            let title = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }
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

    // MARK: - Mileage logic

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

    // ✅ Unified urgency: based on DATE or MILEAGE (whichever sooner)
    private func unifiedUrgency(item: MaintenanceItem, carMileage: Int32) -> (color: Color, label: String, effectiveDays: Int) {
        let d = daysUntil(item.nextChangeDate)

        let dueMileage = resolvedNextMileage(for: item)
        let overdueByMileage = (dueMileage > 0) && (carMileage >= dueMileage)
        let overdueByDate = d < 0

        if overdueByMileage || overdueByDate {
            return (.red, "overdue", min(d, 0))
        }

        if dueMileage > 0 {
            let remain = max(0, Int(kmRemaining(item: item, carMileage: carMileage)))
            let estDaysByKm = avgKmPerDay > 0 ? Int(ceil(Double(remain) / avgKmPerDay)) : 9999
            let effectiveDays = min(d, estDaysByKm)

            if effectiveDays == 0 { return (.orange, "today", 0) }
            if effectiveDays <= 2 { return (.orange, "in \(effectiveDays)d", effectiveDays) }
            if effectiveDays <= 7 { return (.yellow, "in \(effectiveDays)d", effectiveDays) }
            return (.green, "in \(effectiveDays)d", effectiveDays)
        }

        if d == 0 { return (.orange, "today", 0) }
        if d <= 2 { return (.orange, "in \(d)d", d) }
        if d <= 7 { return (.yellow, "in \(d)d", d) }
        return (.green, "in \(d)d", d)
    }

    // MARK: - Rules filter

    private func allowedTasks(for car: Car) -> [String] {
        MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
    }

    private var baseItemsForSelectedCar: [MaintenanceItem] {
        guard let car = selectedCar else { return [] }

        let carItems = items.filter { $0.car == car }
        let allowed = allowedTasks(for: car)
        let all = allowed.isEmpty ? carItems : carItems.filter { allowed.contains($0.title ?? "") }

        return removeDuplicates(all)
    }

    private var searchedItems: [MaintenanceItem] {
        let list = baseItemsForSelectedCar
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return list }

        return list.filter {
            ($0.title ?? "").lowercased().contains(q) ||
            ($0.category ?? "").lowercased().contains(q)
        }
    }

    private var filteredItems: [MaintenanceItem] {
        guard let car = selectedCar else { return [] }
        let carMileage = car.mileage

        switch filter {
        case .all:
            return searchedItems

        case .urgent:
            return searchedItems.filter {
                let u = unifiedUrgency(item: $0, carMileage: carMileage)
                return u.color == .red || u.effectiveDays <= 7
            }

        case .upcoming:
            return searchedItems.filter {
                let u = unifiedUrgency(item: $0, carMileage: carMileage)
                return u.color != .red && u.effectiveDays > 7
            }

        case .overdue:
            return searchedItems.filter {
                let u = unifiedUrgency(item: $0, carMileage: carMileage)
                return u.color == .red
            }
        }
    }

    // MARK: - Maintenance → Service type

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

            VStack(spacing: 14) {
                Text("Maintenance Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .padding(.top, 28)

                // Search
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.55))
                    TextField("Search tasks…", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)

                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Filter.allCases, id: \.self) { f in
                            filterPill(f)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Content
                if selectedCar == nil {
                    VStack(spacing: 12) {
                        Text("No car selected.")
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.top, 30)

                        Text("Select a car to see your schedule.")
                            .foregroundColor(.white.opacity(0.55))
                            .font(.subheadline)

                        NeonButton(title: "Select a car") {
                            showSelectCar = true
                        }
                        .padding(.horizontal, 60)
                        .padding(.top, 6)
                    }
                    .padding(.top, 10)

                } else if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Text("No tasks found.")
                            .foregroundColor(.white.opacity(0.75))
                            .padding(.top, 30)

                        Text("Try another filter or clear search.")
                            .foregroundColor(.white.opacity(0.55))
                            .font(.subheadline)
                    }

                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(filteredItems) { item in
                                    Button {
                                        guard selectedCar != nil else { return }
                                        quickLogItem = item
                                    } label: {
                                        scheduleRow(item)
                                    }
                                    .buttonStyle(.plain)
                                    .id(item.objectID)
                                    .contextMenu {
                                        Button("Quick log") {
                                            guard selectedCar != nil else { return }
                                            quickLogItem = item
                                        }
                                        Button(role: .destructive) {
                                            deleteTask(item)
                                        } label: {
                                            Text("Delete")
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .id(refreshID)
                        .onAppear {
                            if let focusItem {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                    proxy.scrollTo(focusItem.objectID, anchor: .top)
                                }
                            }
                        }
                        .refreshable {
                            refreshID = UUID()
                        }
                    }
                }

                Spacer()

                NeonButton(title: "Add Maintenance Task") {
                    showAddItem = true
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
            }
        }
        .onChange(of: avgKmPerDay) { _, _ in
            refreshID = UUID()
        }
        .sheet(isPresented: $showAddItem) {
            AddMaintenanceItemView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showSelectCar) {
            CarSelectionView(hasSelectedCar: .constant(true))
                .environment(\.managedObjectContext, viewContext)
        }
        // ✅ FIX: sheet(item:) = never opens blank
        .sheet(item: $quickLogItem) { item in
            if let car = selectedCar {
                AddServiceView(
                    prefilledType: serviceTypeForMaintenance(item),
                    prefilledMileage: car.mileage,
                    prefilledDate: Date(),
                    maintenanceItemID: item.objectID
                )
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(tabBar)
            } else {
                Text("No active car.")
                    .foregroundColor(.white)
                    .presentationDetents([.medium])
            }
        }
    }

    private func filterPill(_ f: Filter) -> some View {
        let isOn = (filter == f)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { filter = f }
        } label: {
            Text(f.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundColor(isOn ? .black : .white.opacity(0.9))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isOn ? Color(hex: "#FFD54F") : Color.white.opacity(0.06))
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isOn ? Color.clear : Color.cyan.opacity(0.25), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func scheduleRow(_ item: MaintenanceItem) -> some View {
        let carMileage: Int32 = selectedCar?.mileage ?? 0
        let u = unifiedUrgency(item: item, carMileage: carMileage)

        let dueMileage = resolvedNextMileage(for: item)
        let remainKm = kmRemaining(item: item, carMileage: carMileage)
        let estKmAtDate = estimatedMileageAtDate(carMileage: carMileage, nextDate: item.nextChangeDate)

        let isFocused = (focusItem?.objectID == item.objectID)

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
                .allowsHitTesting(false) // ✅ IMPORTANT: badge won't steal taps
        }
        .padding()
        .background(isFocused ? Color(hex: "#FFD54F").opacity(0.12) : Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isFocused ? Color(hex: "#FFD54F") : .clear, lineWidth: 1.4)
        )
        .shadow(color: u.color.opacity(0.18), radius: 6)
        .padding(.horizontal, 16)
    }

    private func deleteTask(_ item: MaintenanceItem) {
        withAnimation {
            viewContext.delete(item)
            do {
                try viewContext.save()
            } catch {
                print("❌ deleteTask save error:", error)
            }
        }
    }
}


#Preview {
    NavigationStack {
        MaintenanceScheduleView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(TabBarVisibility())
    }
}
