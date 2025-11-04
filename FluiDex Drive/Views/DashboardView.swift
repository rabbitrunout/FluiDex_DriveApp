import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("currentUserName") private var currentUserName: String = "Guest"
    @AppStorage("currentUserEmail") private var currentUserEmail: String = "user@example.com"

    // 🧭 Активная машина
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true"),
        animation: .easeInOut
    ) private var selectedCar: FetchedResults<Car>

    // 🔧 Все сервисные записи
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    @State private var showAddService = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            // 🌌 Фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // 🧍 Профиль
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(Color(hex: "#FFD54F"))
                            )
                            .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUserName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text(currentUserEmail)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Button {
                            showEditProfile = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.7), radius: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)

                    Divider()
                        .overlay(Color.cyan.opacity(0.4))
                        .padding(.horizontal, 60)

                    // 🚗 Активная машина
                    if let car = selectedCar.first {
                        VStack(spacing: 12) {
                            if let image = UIImage(named: car.imageName ?? "") {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 160)
                                    .cornerRadius(20)
                                    .shadow(color: .cyan.opacity(0.5), radius: 20, y: 8)
                            } else {
                                Image(systemName: "car.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 90)
                                    .foregroundColor(.yellow)
                                    .shadow(color: .cyan.opacity(0.8), radius: 10)
                            }

                            Text(car.name ?? "Unknown Car")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .cyan.opacity(0.8), radius: 10)

                            Text("\(car.year ?? "Year Unknown") • \(car.mileage) km")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                        }
                        .padding(.top, 10)
                    } else {
                        Text("No car selected")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 40)
                    }

                    Divider()
                        .overlay(Color.cyan.opacity(0.3))
                        .padding(.horizontal, 60)

                    // 📊 Следующее ТО
                    if let next = getNextService(for: selectedCar.first) {
                        VStack(spacing: 10) {
                            Text("Next Service Due:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))

                            Text("\(next.mileage) km • \(formatDate(next.date))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD54F"))
                                .shadow(color: .yellow.opacity(0.5), radius: 8)
                        }
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                        .shadow(color: .cyan.opacity(0.3), radius: 8)
                    }

                    // 🧾 Последние сервисы
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent Services")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 20)

                        if recentServices(for: selectedCar.first).isEmpty {
                            Text("No service records yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.leading, 20)
                        } else {
                            ForEach(recentServices(for: selectedCar.first)) { record in
                                HStack(spacing: 16) {
                                    Image(systemName: iconForType(record.type ?? ""))
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 20))
                                        .shadow(color: .yellow.opacity(0.5), radius: 5)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.type ?? "Unknown")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)

                                        Text("\(record.mileage) km • \(formatDate(record.date))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.7))
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.2), radius: 6)
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    // 🌈 Переход к расписанию обслуживания
                    NavigationLink(destination: MaintenanceScheduleView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.6), radius: 8)
                                .font(.title3)
                            Text("View Maintenance Schedule")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                        .shadow(color: .cyan.opacity(0.4), radius: 8)
                        .padding(.horizontal, 40)
                    }
                    .padding(.top, 12)

                    // 🛠 Upcoming Maintenance Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Upcoming Maintenance")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 20)
                            .padding(.top, 10)
                        
                        let upcomingItems = getUpcomingMaintenance(for: selectedCar.first)
                        
                        if upcomingItems.isEmpty {
                            Text("No upcoming maintenance tasks.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.leading, 20)
                        } else {
                            ForEach(upcomingItems.indices, id: \.self) { index in
                                let item = upcomingItems[index]
                                
                                HStack(spacing: 16) {
                                    // 🔧 Иконка типа обслуживания
                                    Image(systemName: iconForMaintenance(item.title ?? ""))
                                        .font(.system(size: 22))
                                        .foregroundColor(colorForDate(item.nextChangeDate))
                                        .shadow(color: colorForDate(item.nextChangeDate).opacity(0.8), radius: 6)
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.title ?? "Unknown Task")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Due: \(formatDate(item.nextChangeDate))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    Spacer()
                                    
                                    Image(systemName: "calendar.badge.exclamationmark")
                                        .foregroundColor(colorForDate(item.nextChangeDate))
                                        .shadow(color: .cyan.opacity(0.4), radius: 6)
                                }
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.3), radius: 8)
                                .padding(.horizontal, 20)
                                .opacity(0.0)
                                .offset(y: 30)
                                .animation(.easeOut(duration: 0.6).delay(Double(index) * 0.15), value: upcomingItems)
                                .onAppear {
                                    withAnimation {
                                        // Этот блок просто триггерит анимацию при появлении
                                    }
                                }
                            }

                        }
                    }
                    .padding(.bottom, 10)


                    // ➕ Добавить сервис
                    NeonButton(title: "Add Service Record") {
                        showAddService = true
                    }
                    .sheet(isPresented: $showAddService) {
                        AddServiceView()
                            .environment(\.managedObjectContext, viewContext)
                    }

                    Spacer(minLength: 60)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(currentName: $currentUserName, currentEmail: $currentUserEmail)
        }
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "Oil": return "oil.drop.fill"
        case "Tires": return "circle.grid.cross"
        case "Fluids": return "thermometer.snowflake"
        case "Battery": return "bolt.car.fill"
        case "Brakes": return "car.rear.waves.up"
        default: return "wrench.and.screwdriver"
        }
    }

    private func recentServices(for car: Car?) -> [ServiceRecord] {
        guard let car else { return [] }
        return allRecords.filter { $0.car == car }.prefix(3).map { $0 }
    }

    private func getNextService(for car: Car?) -> (mileage: Int32, date: Date)? {
        guard let car else { return nil }
        guard let last = allRecords
            .filter({ $0.car == car })
            .sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) })
            .first
        else { return nil }

        return (last.nextServiceKm, last.nextServiceDate ?? Date())
    }

    // MARK: - Maintenance Helpers
    private func getUpcomingMaintenance(for car: Car?) -> [MaintenanceItem] {
        guard let car else { return [] }
        
        let fetchRequest: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "car == %@", car)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)]
        
        do {
            let allItems = try viewContext.fetch(fetchRequest)
            let weekAhead = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
            return allItems.filter { ($0.nextChangeDate ?? Date.distantFuture) <= weekAhead }
        } catch {
            print("❌ Failed to fetch maintenance items: \(error)")
            return []
        }
    }

    private func colorForDate(_ date: Date?) -> Color {
        guard let date else { return .gray }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        switch days {
        case ..<0:
            return .red // просрочено
        case 0...2:
            return .orange // почти срок
        case 3...7:
            return .yellow // скоро
        default:
            return .cyan // всё ок
        }
    }
    private func iconForMaintenance(_ title: String) -> String {
        let lower = title.lowercased()
        if lower.contains("oil") { return "oil.drop.fill" }
        if lower.contains("brake") { return "car.rear.waves.up" }
        if lower.contains("battery") { return "bolt.car.fill" }
        if lower.contains("tire") { return "circle.grid.cross" }
        if lower.contains("coolant") || lower.contains("fluid") { return "thermometer.snowflake" }
        if lower.contains("filter") { return "aqi.medium" }
        if lower.contains("transmission") { return "gearshape.2.fill" }
        if lower.contains("inspection") { return "wrench.and.screwdriver" }
        return "calendar" // дефолтная иконка
    }

}

#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
