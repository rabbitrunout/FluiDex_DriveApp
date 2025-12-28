import SwiftUI
import CoreData
import Foundation

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userName") private var currentUserName: String = "Guest"

    @State private var showProfile = false
    @State private var showAddService = false
    @State private var carOpacity: CGFloat = 0

    // ✅ для перехода по тапу на срочный maintenance
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

                    Spacer().frame(height: 52)

                    // ✅ компактный header + shrink on scroll
                    carHeaderCompact

                    TripHUDView()
                        .padding(.horizontal, 20)

                    Divider()
                        .overlay(Color.cyan.opacity(0.3))
                        .padding(.horizontal, 60)

                    nextServiceBlockWithUrgency
                    recentServicesBlock
                    upcomingMaintenanceBlock
                    scheduleLink

                    NeonButton(title: "Add Service Record") {
                        showAddService = true
                    }
                    .sheet(isPresented: $showAddService) {
                        AddServiceView()
                            .environment(\.managedObjectContext, viewContext)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.bottom, 18)
            }

            profileBadge
                .padding(.trailing, 18)
                .padding(.top, 18)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView(isLoggedIn: .constant(true))
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $selectedMaintenance) { item in
            MaintenanceScheduleView(focusItem: item)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Profile Badge
    private var profileBadge: some View {
        Button {
            showProfile = true
        } label: {
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
            .shadow(color: .yellow.opacity(0.3), radius: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - ✅ Compact Car Header with scroll shrink
    private var carHeaderCompact: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .global).minY
            let shrink = clamp((-minY) / 180, 0, 1)            // 0...1
            let imageHeight = lerp(from: 185, to: 120, t: shrink)
            let titleSize = lerp(from: 26, to: 22, t: shrink)
            let subOpacity = 1 - 0.25 * shrink

            VStack(spacing: 10) {
                if let car = selectedCar.first {
                    ZStack {
                        Circle()
                            .fill(Color.cyan.opacity(0.28))
                            .blur(radius: 25)
                            .frame(width: 240, height: 34)
                            .offset(y: imageHeight * 0.42)

                        Image(uiImage: UIImage(named: car.imageName ?? "") ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(height: imageHeight)
                            .shadow(color: .cyan.opacity(0.7), radius: 30)
                            .opacity(carOpacity)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.8)) { carOpacity = 1 }
                            }
                            .scaleEffect(1 - 0.05 * shrink) // легкое сжатие
                            .animation(.easeOut(duration: 0.2), value: shrink)
                    }

                    Text(car.name ?? "Unknown Car")
                        .font(.system(size: titleSize, weight: .bold))
                        .foregroundColor(.white)
                        .animation(.easeOut(duration: 0.2), value: shrink)

                    Text("\(car.year ?? "") • \(car.mileage) km")
                        .foregroundColor(.white.opacity(0.7 * subOpacity))
                        .animation(.easeOut(duration: 0.2), value: shrink)
                } else {
                    Text("No car selected")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 250) // контейнер header (можно чуть уменьшить, если хочешь)
        .padding(.horizontal, 16)
    }

    // MARK: - ✅ Next Service + urgency badge
    private var nextServiceBlockWithUrgency: some View {
        Group {
            if let car = selectedCar.first,
               let next = getNextService(for: car) {

                let urgency = serviceUrgency(for: next.date)

                VStack(spacing: 10) {
                    HStack {
                        Text("Next Service Due:")
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        // badge: ● overdue / in X days
                        HStack(spacing: 8) {
                            Circle()
                                .fill(urgency.color)
                                .frame(width: 8, height: 8)

                            Text(urgency.label)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(urgency.color.opacity(0.35), lineWidth: 1)
                        )
                    }

                    Text("\(next.mileage) km • \(formatDate(next.date))")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
                .padding(.horizontal, 20)
            }
        }
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
                ForEach(items) { record in
                    HStack(spacing: 16) {
                        Image(systemName: iconForType(record.type ?? ""))
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.type ?? "")
                                .foregroundColor(.white)
                            Text("\(record.mileage) km • \(formatDate(record.date))")
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

    // MARK: - Upcoming Maintenance (urgent only) + Tap to focus
    private var upcomingMaintenanceBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Upcoming Maintenance")
                .foregroundColor(.white)
                .padding(.leading, 20)

            if let car = selectedCar.first {
                let urgent = urgentMaintenance(for: car)

                if urgent.isEmpty {
                    Text("No urgent tasks. You’re all set ✅")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.leading, 20)
                } else {
                    VStack(spacing: 14) {
                        ForEach(urgent, id: \.self) { item in
                            Button {
                                selectedMaintenance = item
                            } label: {
                                HStack {
                                    Circle()
                                        .fill(urgencyColor(for: item))
                                        .frame(width: 10, height: 10)

                                    Text(item.title ?? "")
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text(formatDate(item.nextChangeDate))
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.white.opacity(0.35))
                                        .font(.caption.weight(.semibold))
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(16)
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 20)
                        }
                    }
                }
            } else {
                Text("No car selected")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.leading, 20)
            }
        }
    }

    // MARK: - Schedule Link
    private var scheduleLink: some View {
        VStack(alignment: .leading) {
            Text("Maintenance Schedule")
                .foregroundColor(.white)
                .padding(.leading, 20)

            NavigationLink(destination: MaintenanceScheduleView(focusItem: nil)) {
                HStack {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.cyan)
                    Text("View full schedule")
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Helpers (maintenance list)

    private func urgentMaintenance(for car: Car) -> [MaintenanceItem] {
        let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        req.predicate = NSPredicate(format: "car == %@", car)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)]

        let items = (try? viewContext.fetch(req)) ?? []

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let filtered = allowed.isEmpty
            ? items
            : items.filter { allowed.contains($0.title ?? "") }

        let unique = removeDuplicates(filtered)

        return unique
            .filter { daysUntil($0.nextChangeDate) <= 7 } // urgent <= 7 days (incl overdue)
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

    // MARK: - Helpers (Next Service urgency badge)

    private struct ServiceUrgency {
        let label: String
        let color: Color
    }

    private func serviceUrgency(for nextDate: Date) -> ServiceUrgency {
        let d = Calendar.current.dateComponents([.day], from: Date(), to: nextDate).day ?? 999

        if d < 0 {
            return ServiceUrgency(label: "overdue", color: .red)
        } else if d == 0 {
            return ServiceUrgency(label: "today", color: .orange)
        } else if d <= 2 {
            return ServiceUrgency(label: "in \(d) day\(d == 1 ? "" : "s")", color: .orange)
        } else if d <= 7 {
            return ServiceUrgency(label: "in \(d) days", color: .yellow)
        } else {
            return ServiceUrgency(label: "in \(d) days", color: .green)
        }
    }

    // MARK: - Helpers (services)

    private func recentServices(for car: Car?) -> [ServiceRecord] {
        guard let car else { return [] }
        return Array(allRecords.filter { $0.car == car }.prefix(3))
    }

    private func getNextService(for car: Car) -> (mileage: Int32, date: Date)? {
        guard let last = allRecords.first(where: { $0.car == car }) else { return nil }
        return (last.nextServiceKm, last.nextServiceDate ?? Date())
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

    // MARK: - Math helpers

    private func clamp(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat {
        min(max(v, minV), maxV)
    }

    private func lerp(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }
}

#Preview {
    NavigationStack {
        DashboardView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
