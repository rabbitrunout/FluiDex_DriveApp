import SwiftUI
import CoreData
import Foundation

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userName") private var currentUserName: String = "Guest"

    @State private var showProfile = false
    @State private var showAddService = false

    // быстрый лог, когда нажали Next Service
    @State private var showQuickServiceLog = false

    @State private var carOpacity: CGFloat = 0
    @State private var selectedMaintenance: MaintenanceItem? = nil

    // MARK: - CoreData
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    ) private var selectedCar: FetchedResults<Car>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)]
    ) private var allRecords: FetchedResults<ServiceRecord>

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
        .sheet(isPresented: $showProfile) {
            ProfileView(isLoggedIn: .constant(true))
                .environment(\.managedObjectContext, viewContext)
        }

        // ✅ тап по maintenance alert → открываем schedule + фокус
        .sheet(item: $selectedMaintenance) { item in
            MaintenanceScheduleView(focusItem: item)
                .environment(\.managedObjectContext, viewContext)
        }

        // ✅ тап по Next Service → быстрый лог сервиса (prefilled AddServiceView)
        .sheet(isPresented: $showQuickServiceLog) {
            AddServiceView(
                prefilledType: "Oil",
                prefilledMileage: selectedCar.first?.mileage ?? 0,
                prefilledDate: Date()
            )
            .environment(\.managedObjectContext, viewContext)
        }
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
            if let car = selectedCar.first {
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

                // ✅ car.year = String
                Text("\(car.year ?? "—") • \(car.mileage) km")
                    .foregroundColor(.white.opacity(0.7))

            } else {
                Text("No car selected")
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Next Service (кликабельно + badge срочности + красная рамка)
    private var nextServiceCard: some View {
        Group {
            if let car = selectedCar.first,
               let next = getNextService(for: car) {

                let badge = nextServiceBadge(nextDate: next.date,
                                             dueMileage: next.mileage,
                                             currentMileage: car.mileage)

                Button {
                    showQuickServiceLog = true
                } label: {
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
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(text)
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.45), lineWidth: 1)
        )
    }

    /// ✅ одна логика “overdue”: по дате ИЛИ по пробегу
    private func nextServiceBadge(nextDate: Date, dueMileage: Int32, currentMileage: Int32) -> (text: String, color: Color) {
        let overdueByMileage = currentMileage >= dueMileage

        let days = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 999
        let overdueByDate = days < 0

        if overdueByMileage || overdueByDate {
            return ("overdue", .red)
        }
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

            let items = recentServices(for: selectedCar.first)

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

    // MARK: - Maintenance (одна карточка, без дублей)
    private var maintenanceCard: some View {
        // ✅ заранее считаем, чтобы компилятор не “умирал”
        let car = selectedCar.first
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
                            Button {
                                selectedMaintenance = item
                            } label: {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(urgencyColor(for: item))
                                        .frame(width: 10, height: 10)

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

    // MARK: - Helpers

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

    /// ✅ Optional tuple (иначе будет ошибка conditional binding)
    private func getNextService(for car: Car) -> (mileage: Int32, date: Date)? {
        guard let last = allRecords.first(where: { $0.car == car }) else { return nil }
        return (last.nextServiceKm, last.nextServiceDate ?? Date())
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
