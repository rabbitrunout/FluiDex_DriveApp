import SwiftUI
import CoreData
import Foundation

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userName") private var currentUserName: String = "Guest"

    @State private var showProfile = false
    @State private var showAddService = false

    @State private var carOpacity: CGFloat = 0
    @State private var glowPulse = false

    // 🔗 выбранный алерт (ШАГ 2)
    @State private var selectedMaintenance: MaintenanceItem?

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
                VStack(spacing: 28) {

                    Spacer().frame(height: 55)

                    carBlock
                    TripHUDView().padding(.horizontal, 20)

                    Divider()
                        .overlay(Color.cyan.opacity(0.3))
                        .padding(.horizontal, 60)

                    nextServiceBlock
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
        .sheet(item: $selectedMaintenance) { item in
            NavigationStack {
                MaintenanceScheduleView(focusItem: item)
                    .environment(\.managedObjectContext, viewContext)
            }
        }



    }

    // MARK: - Profile badge
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
    }

    // MARK: - CAR
    private var carBlock: some View {
        VStack(spacing: 12) {
            if let car = selectedCar.first {
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.28))
                        .blur(radius: 25)
                        .frame(width: 260, height: 40)
                        .offset(y: 90)

                    Image(uiImage: UIImage(named: car.imageName ?? "") ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(height: 185)
                        .shadow(color: .cyan.opacity(0.7), radius: 30)
                        .opacity(carOpacity)
                        .onAppear {
                            withAnimation(.easeOut(duration: 0.8)) {
                                carOpacity = 1
                            }
                        }
                }

                Text(car.name ?? "Unknown Car")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("\(car.year ?? "") • \(car.mileage) km")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - NEXT SERVICE
    private var nextServiceBlock: some View {
        Group {
            if let car = selectedCar.first,
               let next = getNextService(for: car) {
                VStack(spacing: 10) {
                    Text("Next Service Due:")
                        .foregroundColor(.white.opacity(0.7))

                    Text("\(next.mileage) km • \(formatDate(next.date))")
                        .font(.headline)
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .cornerRadius(16)
            }
        }
    }

    // MARK: - RECENT
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
                    HStack {
                        Image(systemName: iconForType(record.type ?? ""))
                            .foregroundColor(.yellow)

                        VStack(alignment: .leading) {
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

    // MARK: - UPCOMING (tap enabled)
    @ViewBuilder
    private var upcomingMaintenanceBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Upcoming Maintenance")
                .foregroundColor(.white)
                .padding(.leading, 20)

            if let car = selectedCar.first {

                let raw = getUpcomingMaintenance(for: car)
                let unique = removeDuplicates(raw)
                let urgent = unique.filter { daysUntil($0.nextChangeDate) <= 7 }

                if urgent.isEmpty {
                    Text("No urgent tasks. You’re all set ✅")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.leading, 20)
                } else {
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
        }
    }

    // MARK: - LINK
    private var scheduleLink: some View {
        VStack(alignment: .leading) {
            Text("Maintenance Schedule")
                .foregroundColor(.white)
                .padding(.leading, 20)

            NavigationLink(destination: MaintenanceScheduleView()) {
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

    // MARK: - HELPERS

    private func getUpcomingMaintenance(for car: Car) -> [MaintenanceItem] {
        let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        req.predicate = NSPredicate(format: "car == %@", car)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)]
        return (try? viewContext.fetch(req)) ?? []
    }

    private func removeDuplicates(_ items: [MaintenanceItem]) -> [MaintenanceItem] {
        var map: [String: MaintenanceItem] = [:]
        for item in items {
            let key = item.title ?? ""
            if let existing = map[key] {
                if let d1 = item.nextChangeDate,
                   let d2 = existing.nextChangeDate,
                   d1 < d2 {
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
        return (last.nextServiceKm, last.nextServiceDate ?? Date())
    }
}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
