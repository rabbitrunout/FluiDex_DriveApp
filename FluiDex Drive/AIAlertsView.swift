import SwiftUI
import CoreData
import Foundation

struct AIAlertsView: View {
    @Environment(\.managedObjectContext) private var context

    // Активная машина
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    )
    private var selectedCar: FetchedResults<Car>

    // История сервисов для AI
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)]
    )
    private var records: FetchedResults<ServiceRecord>

    // Все задачи обслуживания
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)]
    )
    private var allItems: FetchedResults<MaintenanceItem>

    @State private var predictions: [MaintenancePrediction] = []

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    Text("AI & Alerts")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.5), radius: 10)
                        .padding(.top, 30)

                    aiPredictionsSection
                    alertsSection
                }
            }
            .onAppear(perform: loadAI)
        }
    }

    // MARK: - AI Predictions Section
    private var aiPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔮 Smart AI Predictions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if predictions.isEmpty {
                Text("Analyzing your car data…")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
            } else {
                ForEach(predictions) { pred in
                    predictionRow(pred)
                }
            }
        }
    }

    private func predictionRow(_ pred: MaintenancePrediction) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconForType(pred.type))
                    .foregroundColor(.cyan)
                Text(pred.type)
                    .foregroundColor(.white)
                    .font(.headline)
            }

            Text("Next service: \(format(pred.nextDate)) • ≈ \(pred.nextMileage) km")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)

            ProgressView(value: progress(for: pred))
                .tint(.cyan)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .shadow(color: .cyan.opacity(0.3), radius: 8)
        .padding(.horizontal, 20)
    }

    // MARK: - Alerts Section (ВСЕ задачи, но отсортированные по срочности)
    private var alertsSection: some View {
        let items = allAlertsForSelectedCar()

        return VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Maintenance Overview")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if items.isEmpty {
                Text("No maintenance tasks yet for this car.")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 20)
            } else {
                ForEach(items, id: \.self) { item in
                    alertRow(item)
                }
            }
        }
    }

    private func alertRow(_ item: MaintenanceItem) -> some View {
        let color = urgencyColor(for: item)

        return HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? "")
                    .foregroundColor(.white)

                Text("Next: \(format(item.nextChangeDate))")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.4), radius: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - Filtering & Logic

    /// Все задачи для выбранной машины и её fuelType (БЕЗ обрезки по 7 дням),
    /// без дублей, отсортированы по срочности.
    private func allAlertsForSelectedCar() -> [MaintenanceItem] {
        guard let car = selectedCar.first else { return [] }

        // 1️⃣ задачи только этой машины
        let carItems = allItems.filter { $0.car == car }

        // 2️⃣ фильтр по fuelType (MaintenanceRules)
        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let filtered = allowed.isEmpty
            ? carItems
            : carItems.filter { allowed.contains($0.title ?? "") }

        // 3️⃣ убираем дубли по title, оставляя ближайшую дату
        let unique = removeDuplicates(filtered)

        // 4️⃣ сортируем по уровню срочности, потом по дате
        return unique.sorted { a, b in
            let ua = urgencyLevel(a)
            let ub = urgencyLevel(b)

            if ua != ub { return ua < ub }
            return (a.nextChangeDate ?? .distantFuture) < (b.nextChangeDate ?? .distantFuture)
        }
    }

    private func removeDuplicates(_ items: [MaintenanceItem]) -> [MaintenanceItem] {
        var map: [String: MaintenanceItem] = [:]

        for item in items {
            let title = item.title ?? ""

            if let existing = map[title] {
                if let d1 = item.nextChangeDate,
                   let d2 = existing.nextChangeDate,
                   d1 < d2 {
                    map[title] = item   // оставляем более раннюю дату
                }
            } else {
                map[title] = item
            }
        }

        return Array(map.values)
    }

    private func daysUntil(_ date: Date?) -> Int {
        guard let date else { return 999 }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 999
    }

    /// 0 — 🔥 просрочено, 1 — 🟠, 2 — 🟡, 3 — 🟢
    private func urgencyLevel(_ item: MaintenanceItem) -> Int {
        let d = daysUntil(item.nextChangeDate)
        switch d {
        case ..<0: return 0   // 🔥 overdue
        case 0...2: return 1  // 🟠 urgent
        case 3...7: return 2  // 🟡 soon
        default: return 3     // 🟢 ok
        }
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

    private func progress(for p: MaintenancePrediction) -> Double {
        let days = daysUntil(p.nextDate)
        return 1.0 - min(max(Double(days), 0) / 30.0, 1.0)
    }

    private func iconForType(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("oil") { return "oil.drop.fill" }
        if t.contains("brake") { return "car.rear.waves.up" }
        if t.contains("battery") { return "bolt.car.fill" }
        if t.contains("tire") { return "circle.grid.cross" }
        if t.contains("filter") { return "aqi.medium" }
        return "wrench.and.screwdriver"
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }

    private func loadAI() {
        guard let car = selectedCar.first else { return }
        let carRecords = records.filter { $0.car == car }
        predictions = AIMaintenanceEngine.shared.predictNextMaintenance(
            for: car,
            using: carRecords
        )
    }
}

#Preview {
    AIAlertsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
