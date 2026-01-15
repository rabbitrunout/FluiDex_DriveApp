import SwiftUI
import CoreData
import Foundation

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("userName") private var currentUserName: String = "Guest"
    @AppStorage("userEmail") private var currentUserEmail: String = ""

    @State private var showProfile = false
    @State private var showAddService = false
    @State private var showQuickServiceLog = false
    @State private var carOpacity: CGFloat = 0
    @State private var selectedMaintenance: MaintenanceItem? = nil

    // ✅ Fetch ALL cars once, filter locally
    @FetchRequest(sortDescriptors: [], predicate: nil, animation: .easeInOut)
    private var allCars: FetchedResults<Car>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)]
    ) private var allRecords: FetchedResults<ServiceRecord>

    private var owner: String {
        currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    // ✅ cars only for this user
    private var userCars: [Car] {
        guard !owner.isEmpty else { return [] }
        return allCars.filter { ($0.ownerEmail ?? "").lowercased() == owner }
    }

    // ✅ active car only for this user
    private var activeCar: Car? {
        userCars.first(where: { $0.isSelected })
    }

    // MARK: - Latest service record (for active car)
    private var latestRecordForActiveCar: ServiceRecord? {
        guard let car = activeCar else { return nil }
        return allRecords.first(where: { $0.car == car })
    }

    // MARK: - Next due info from latest record
    private var nextDue: (dueKm: Int32, dueDate: Date)? {
        guard let rec = latestRecordForActiveCar else { return nil }
        guard rec.nextServiceKm > 0, let d = rec.nextServiceDate else { return nil }
        return (rec.nextServiceKm, d)
    }

    // MARK: - Remaining fraction (0...1) and warning flag
    /// Uses BOTH mileage + date, picks the "more urgent" (smaller %) as final.
    private func remainingFractionForNextService(car: Car, record: ServiceRecord) -> Double? {
        guard record.nextServiceKm > 0, let nextDate = record.nextServiceDate else { return nil }

        // Interval baseline (from last service -> next service)
        // mileage interval
        let intervalKm = Double(record.nextServiceKm - record.mileage)
        let remainingKm = Double(record.nextServiceKm - car.mileage)

        // date interval
        let baseDate = record.date ?? Date()
        let intervalDays = Double(max(1, Calendar.current.dateComponents([.day], from: baseDate, to: nextDate).day ?? 1))
        let remainingDays = Double(Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 9999)

        var candidates: [Double] = []

        if intervalKm > 0 {
            let kmFrac = remainingKm / intervalKm
            candidates.append(kmFrac)
        }
        // date is meaningful even if km interval is weird
        let dayFrac = remainingDays / intervalDays
        candidates.append(dayFrac)

        // take the most urgent (smallest fraction)
        let raw = candidates.min() ?? 1.0
        return min(max(raw, -1.0), 2.0) // keep sane bounds
    }

    private var shouldShowServiceWarning: Bool {
        guard let car = activeCar,
              let rec = latestRecordForActiveCar,
              let due = nextDue else { return false }

        // overdue if km reached or date passed
        let overdueByKm = car.mileage >= due.dueKm
        let days = Calendar.current.dateComponents([.day], from: Date(), to: due.dueDate).day ?? 999
        let overdueByDate = days < 0
        if overdueByKm || overdueByDate { return true }

        // <20% remaining logic
        if let frac = remainingFractionForNextService(car: car, record: rec) {
            return frac < 0.20
        }
        return false
    }

    private var warningBannerText: (title: String, message: String)? {
        guard let car = activeCar,
              let rec = latestRecordForActiveCar,
              let due = nextDue else { return nil }

        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: due.dueDate).day ?? 999
        let kmLeft = Int(due.dueKm - car.mileage)

        let overdueByKm = car.mileage >= due.dueKm
        let overdueByDate = daysLeft < 0

        if overdueByKm || overdueByDate {
            return (
                "Service overdue",
                "Next service was due at \(Int(due.dueKm)) km / \(formatDate(due.dueDate))."
            )
        }

        // <20% case
        if let frac = remainingFractionForNextService(car: car, record: rec) {
            let pct = Int((max(0, min(frac, 1.0))) * 100)
            return (
                "Service due soon",
                "Only \(pct)% left • \(max(kmLeft, 0)) km • \(max(daysLeft, 0)) days"
            )
        }

        return nil
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {

            LinearGradient(
                gradient: Gradient(colors: [.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer().frame(height: 55)

                    carBlock

                    TripHUDView()
                        .padding(.horizontal, 20)

                    // ✅🔥 IDEAL place for WarningBanner (under TripHUD, before nextService)
                    if shouldShowServiceWarning, let info = warningBannerText {
                        WarningBanner(title: info.title, message: info.message)
                    }

                    Divider()
                        .overlay(Color.cyan.opacity(0.25))
                        .padding(.horizontal, 60)

                    nextServiceCard
                    recentServicesBlock
                    maintenanceCard

                    NeonButton(title: "Add Service Record") {
                        showAddService = true
                    }
                    .sheet(isPresented: $showAddService) {
                        AddServiceView(
                            prefilledType: nil,
                            prefilledMileage: nil,
                            prefilledDate: nil
                        )
                        .environment(\.managedObjectContext, viewContext)
                    }

                    Spacer(minLength: 50)
                }
            }

            profileBadge
                .padding(.trailing, 18)
                .padding(.top, 18)
        }
        .onAppear {
            fixActiveCarIfNeeded()
        }
        .onChange(of: currentUserEmail) { _, _ in
            fixActiveCarIfNeeded()
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(isLoggedIn: .constant(true))
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedMaintenance) { item in
            MaintenanceScheduleView(focusItem: item)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showQuickServiceLog) {
            AddServiceView(
                prefilledType: "Oil",
                prefilledMileage: activeCar?.mileage ?? 0,
                prefilledDate: Date()
            )
            .environment(\.managedObjectContext, viewContext)
        }
    }

    // ✅ IMPORTANT: make selection consistent (and global unique isSelected)
    private func fixActiveCarIfNeeded() {
        guard !owner.isEmpty else { return }

        guard !userCars.isEmpty else {
            carOpacity = 0
            return
        }

        if activeCar != nil {
            carOpacity = 0
            return
        }

        setGlobalActiveCar(userCars.first!)
    }

    private func setGlobalActiveCar(_ car: Car) {
        for c in allCars { c.isSelected = false }
        car.isSelected = true
        try? viewContext.save()
        carOpacity = 0
    }

    // MARK: - Profile badge
    private var profileBadge: some View {
        Button { showProfile = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "#FFD54F"))

                Text(currentUserName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.07))
            .cornerRadius(20)
            .shadow(color: .yellow.opacity(0.25), radius: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Car header
    private var carBlock: some View {
        VStack(spacing: 12) {
            if let car = activeCar {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.22))
                        .blur(radius: 25)
                        .frame(width: 260, height: 40)
                        .offset(y: 90)

                    Image(uiImage: UIImage(named: car.imageName ?? "") ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 165)
                        .shadow(color: .cyan.opacity(0.55), radius: 26)
                        .opacity(carOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.8)) { carOpacity = 1 }
                        }
                }

                Text(car.name ?? "Unknown Car")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("\(car.year ?? "—") • \(car.mileage) km")
                    .foregroundColor(.white.opacity(0.7))

            } else {
                VStack(spacing: 10) {
                    Text("No car selected")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.title3.weight(.bold))

                    Text("Add your first car to start tracking maintenance.")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Next Service
    private var nextServiceCard: some View {
        Group {
            if let car = activeCar,
               let next = getNextService(for: car) {

                let badge = nextServiceBadge(
                    nextDate: next.date,
                    dueMileage: next.mileage,
                    currentMileage: car.mileage
                )

                Button { showQuickServiceLog = true } label: {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Next Service Due:")
                                .foregroundColor(.white.opacity(0.7))
                            Spacer()
                            urgencyPill(text: badge.text, color: badge.color)
                        }

                        Text("\(Int(next.mileage)) km • \(formatDate(next.date))")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#FFD54F"))
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(badge.color.opacity(0.45), lineWidth: 1)
                    )
                    .shadow(color: badge.color.opacity(0.22), radius: 10, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
            }
        }
    }

    private func urgencyPill(text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(color.opacity(0.45), lineWidth: 1))
    }

    private func nextServiceBadge(nextDate: Date, dueMileage: Int32, currentMileage: Int32) -> (text: String, color: Color) {
        let overdueByMileage = currentMileage >= dueMileage
        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 999
        let overdueByDate = days < 0

        if overdueByMileage || overdueByDate { return ("overdue", .red) }
        if days <= 2 { return ("in \(days)d", .orange) }
        if days <= 7 { return ("in \(days)d", .yellow) }
        return ("in \(days)d", .green)
    }

    // MARK: - Recent Services
    private var recentServicesBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Services")
                .foregroundColor(.white)
                .padding(.leading, 20)

            let items = recentServices(for: activeCar)

            if items.isEmpty {
                Text("No records yet.")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 20)
            } else {
                ForEach(items, id: \.objectID) { record in
                    HStack(spacing: 14) {
                        Image(systemName: iconForType(record.type ?? ""))
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.type ?? "")
                                .foregroundColor(.white)
                            Text("\(Int(record.mileage)) km • \(formatDate(record.date))")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Maintenance
    private var maintenanceCard: some View {
        let car = activeCar
        let urgent: [MaintenanceItem] = car.map { urgentMaintenance(for: $0) } ?? []
        let urgentCount = urgent.count
        let urgentPreview = Array(urgent.prefix(2))

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color(hex: "#FFD54F"))
                    Text("Maintenance")
                        .foregroundColor(.white)
                        .font(.headline)
                }

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(urgentCount == 0 ? .green : .orange)
                        .frame(width: 8, height: 8)

                    Text(urgentCount == 0 ? "All set" : "\(urgentCount) urgent")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }

            if car == nil {
                Text("No car selected")
                    .foregroundColor(.white.opacity(0.6))
            } else {
                if urgentCount == 0 {
                    Text("No urgent maintenance in the next 7 days.")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                } else {
                    VStack(spacing: 10) {
                        ForEach(urgentPreview, id: \.objectID) { item in
                            Button { selectedMaintenance = item } label: {
                                HStack(spacing: 10) {
                                    Circle().fill(urgencyColor(for: item)).frame(width: 10, height: 10)
                                    Text(item.title ?? "")
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(formatDate(item.nextChangeDate))
                                        .foregroundColor(.white.opacity(0.65))
                                        .font(.caption)

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.35))
                                        .font(.caption.weight(.semibold))
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(14)
                            }
                            .buttonStyle(.plain)
                        }

                        if urgentCount > 2 {
                            Text("+\(urgentCount - 2) more")
                                .foregroundColor(.white.opacity(0.55))
                                .font(.caption.weight(.semibold))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.top, 4)
                }

                NavigationLink(destination: MaintenanceScheduleView(focusItem: nil)) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.cyan)
                        Text("See full maintenance schedule")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.white.opacity(0.35))
                            .font(.caption.weight(.semibold))
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(14)
                }
                .padding(.top, 6)
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.25), radius: 10, y: 6)
        .padding(.horizontal, 20)
    }

    // MARK: Helpers
    private func urgentMaintenance(for car: Car) -> [MaintenanceItem] {
        let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        req.predicate = NSPredicate(format: "car == %@", car)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)]

        let items = (try? viewContext.fetch(req)) ?? []

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let filtered = allowed.isEmpty ? items : items.filter { allowed.contains($0.title ?? "") }
        let unique = removeDuplicates(filtered)

        return unique
            .filter { daysUntil($0.nextChangeDate) <= 7 }
            .sorted { ($0.nextChangeDate ?? .distantFuture) < ($1.nextChangeDate ?? .distantFuture) }
    }

    private func removeDuplicates(_ items: [MaintenanceItem]) -> [MaintenanceItem] {
        var map: [String: MaintenanceItem] = [:]
        for item in items {
            let key = item.title ?? ""
            if let existing = map[key] {
                if let d1 = item.nextChangeDate, let d2 = existing.nextChangeDate, d1 < d2 {
                    map[key] = item
                }
            } else {
                map[key] = item
            }
        }
        return Array(map.values)
    }

    private func daysUntil(_ date: Date?) -> Int {
        guard let date else { return 999 }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 999
    }

    private func urgencyColor(for item: MaintenanceItem) -> Color {
        let d = daysUntil(item.nextChangeDate)
        switch d {
        case ..<0: return .red
        case 0...2: return .orange
        case 3...7: return .yellow
        default: return .green
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "Oil": return "oil.drop.fill"
        case "Battery": return "bolt.car.fill"
        case "Fluids": return "thermometer.snowflake"
        case "Brakes": return "car.rear.waves.up"
        default: return "wrench.and.screwdriver"
        }
    }

    private func recentServices(for car: Car?) -> [ServiceRecord] {
        guard let car else { return [] }
        return Array(allRecords.filter { $0.car == car }.prefix(3))
    }

    private func getNextService(for car: Car) -> (mileage: Int32, date: Date)? {
        guard let last = allRecords.first(where: { $0.car == car }) else { return nil }
        guard last.nextServiceKm > 0, let d = last.nextServiceDate else { return nil }
        return (last.nextServiceKm, d)
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
