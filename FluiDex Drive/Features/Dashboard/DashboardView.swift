import SwiftUI
import CoreData
import Foundation

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("userName") private var currentUserName: String = "Guest"

    // MARK: - Animations
    @State private var carOpacity: CGFloat = 0
    @State private var carBreathing = false
    @State private var glowPulse = false
    @State private var headlightsOn = false

    @State private var parallaxX: CGFloat = 0
    @State private var parallaxY: CGFloat = 0
    @State private var parallaxAmount: Double = 0

    // MARK: - CoreData
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true"),
        animation: .easeInOut
    ) private var selectedCar: FetchedResults<Car>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    @State private var showAddService = false
    @State private var aiPredictions: [MaintenancePrediction] = []

    var body: some View {
        ZStack {

            // MARK: Background
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    // MARK: - Car Block
                    if let car = selectedCar.first {
                        ZStack {

                            // 🌫 Dust glow
                            Circle()
                                .fill(Color.cyan.opacity(0.28))
                                .blur(radius: 25)
                                .frame(width: 260, height: 40)
                                .offset(y: 90)
                                .scaleEffect(glowPulse ? 1.12 : 0.95)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                            // ✨ Dust particles
                            ForEach(0..<14) { _ in
                                Circle()
                                    .fill(Color.cyan.opacity(Double.random(in: 0.1...0.22)))
                                    .frame(width: CGFloat.random(in: 2...6),
                                           height: CGFloat.random(in: 2...6))
                                    .offset(
                                        x: CGFloat.random(in: -130...130),
                                        y: CGFloat.random(in: 80...140)
                                    )
                                    .blur(radius: 2)
                                    .opacity(glowPulse ? 1 : 0.4)
                                    .animation(
                                        .easeInOut(duration: Double.random(in: 1.5...2.8))
                                            .repeatForever(autoreverses: true),
                                        value: glowPulse
                                    )
                            }

                            // 🚗 Car image
                            Image(uiImage: UIImage(named: car.imageName ?? "") ?? UIImage())
                                .resizable()
                                .scaledToFit()
                                .frame(height: 185)
                                .shadow(color: .cyan.opacity(0.7), radius: 30)
                                .rotation3DEffect(.degrees(parallaxAmount), axis: (x: 0, y: 1, z: 0))
                                .scaleEffect(carBreathing ? 1.02 : 0.98)
                                .opacity(carOpacity)
                                .offset(x: parallaxX, y: parallaxY)
                                .modifier(ParallaxMotionModifier(amount: 12))
                                .onAppear {
                                    carOpacity = 0
                                    withAnimation(.easeOut(duration: 0.8)) { carOpacity = 1 }
                                    glowPulse = true
                                    carBreathing = true
                                }

                            // 🔦 Headlights only (NO light sweep)
                            HStack(spacing: 120) {
                                ConeLightView()
                                    .offset(y: 18)
                                    .opacity(headlightsOn ? 1 : 0)

                                ConeLightView()
                                    .offset(y: 18)
                                    .opacity(headlightsOn ? 1 : 0)
                            }
                            .onAppear {
                                withAnimation(.easeInOut(duration: 2).repeatForever()) {
                                    headlightsOn = true
                                }
                            }
                        }

                        Text(car.name ?? "Unknown Car")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .cyan.opacity(0.8), radius: 12)

                        Text("\(car.year ?? "Year Unknown") • \(car.mileage) km")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.7))

                    } else {
                        Text("No car selected")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 40)
                    }
                    
                    TripHUDView()
                        .padding(.horizontal, 20)


                    Divider()
                        .overlay(Color.cyan.opacity(0.3))
                        .padding(.horizontal, 60)

                    // MARK: Next service
                    if let next = getNextService(for: selectedCar.first) {
                        VStack(spacing: 10) {
                            Text("Next Service Due:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))

                            Text("\(next.mileage) km • \(formatDate(next.date))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD54F"))
                        }
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                    }

                    // MARK: Recent Services
                    recentServicesBlock

                    // MARK: Maintenance Schedule
                    scheduleLink

                    // MARK: Upcoming
                    upcomingMaintenanceBlock

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
        }
        .onAppear {
            if let car = selectedCar.first {
                let records = allRecords.filter { $0.car == car }
                aiPredictions = AIMaintenanceEngine.shared.predictNextMaintenance(for: car, using: records)
            }
        }
    }

    // MARK: - Blocks
    // MARK: - Recent Services
    private var recentServicesBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Services")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 20)

            let items = recentServices(for: selectedCar.first)

            if items.isEmpty {
                Text("No records yet.")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 20)
            } else {
                ForEach(items) { record in
                    Button {
                        // позже можно открыть ServiceDetailView(record: record)
                        print("Tapped record: \(record.type ?? "") at \(record.mileage) km")
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: iconForType(record.type ?? ""))
                                .foregroundColor(.yellow)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.type ?? "Unknown")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .semibold))

                                Text("\(record.mileage) km • \(formatDate(record.date))")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.system(size: 13))
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.white.opacity(0.07))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }



    // MARK: - Maintenance Schedule
    private var scheduleLink: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Maintenance Schedule")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 20)

            NavigationLink(destination: MaintenanceScheduleView()) {
                HStack(spacing: 12) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundColor(.cyan)
                        .font(.title3)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("View full schedule")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))

                        Text("Recommended upcoming maintenance")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                }
                .padding()
                .background(Color.white.opacity(0.06))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 40)
            }
        }
    }



    private var upcomingMaintenanceBlock: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Upcoming Maintenance")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.leading, 20)

            let upcoming = getUpcomingMaintenance(for: selectedCar.first)

            if upcoming.isEmpty {
                Text("No upcoming tasks.")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.leading, 20)
            } else {
                ForEach(upcoming.indices, id: \.self) { index in
                    let item = upcoming[index]

                    HStack(spacing: 16) {
                        Image(systemName: iconForMaintenance(item.title ?? ""))
                            .font(.system(size: 22))
                            .foregroundColor(colorForDate(item.nextChangeDate))

                        VStack(alignment: .leading) {
                            Text(item.title ?? "Unknown")
                                .foregroundColor(.white)
                                .font(.system(size: 16, weight: .semibold))

                            Text("Due: \(formatDate(item.nextChangeDate))")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 13))
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Helpers
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "N/A" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
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
        guard let last = allRecords.filter({ $0.car == car }).first else { return nil }
        return (last.nextServiceKm, last.nextServiceDate ?? Date())
    }

    private func getUpcomingMaintenance(for car: Car?) -> [MaintenanceItem] {
        guard let car else { return [] }

        let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        req.predicate = NSPredicate(format: "car == %@", car)
        req.sortDescriptors = [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)]

        return (try? viewContext.fetch(req)) ?? []
    }

    private func colorForDate(_ date: Date?) -> Color {
        guard let date else { return .gray }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0

        switch days {
        case ..<0: return .red
        case 0...2: return .orange
        case 3...7: return .yellow
        default: return .cyan
        }
    }

    private func iconForMaintenance(_ title: String) -> String {
        let t = title.lowercased()

        if t.contains("oil") { return "oil.drop.fill" }
        if t.contains("brake") { return "car.rear.waves.up" }
        if t.contains("battery") { return "bolt.car.fill" }
        if t.contains("tire") { return "circle.grid.cross" }
        if t.contains("fluid") { return "thermometer.snowflake" }
        if t.contains("filter") { return "aqi.medium" }
        if t.contains("transmission") { return "gearshape.2.fill" }
        if t.contains("inspection") { return "wrench.and.screwdriver" }

        return "calendar"
    }
}

// MARK: - Cone Light
struct ConeLightView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 50)
                .fill(Color.cyan.opacity(0.25))
                .blur(radius: 25)
                .frame(width: 60, height: 140)

            RoundedRectangle(cornerRadius: 50)
                .fill(Color.cyan.opacity(0.45))
                .blur(radius: 10)
                .frame(width: 40, height: 120)
        }
        .rotationEffect(.degrees(-6))
        .blendMode(.screen)
    }
}



#Preview {
    DashboardView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
