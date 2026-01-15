import SwiftUI
import CoreData
import Foundation

struct AIAlertsView: View {
    @Environment(\.managedObjectContext) private var context

    @AppStorage("userEmail") private var userEmail: String = ""
    private var owner: String { userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

    @FetchRequest(sortDescriptors: [], animation: .easeInOut)
    private var allCars: FetchedResults<Car>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    )
    private var allRecords: FetchedResults<ServiceRecord>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    )
    private var allItems: FetchedResults<MaintenanceItem>

    @State private var predictions: [MaintenancePrediction] = []
    @State private var isLoadingAI = false
    @State private var errorMessage: String = ""

    private var activeCar: Car? {
        guard !owner.isEmpty else { return nil }
        return allCars.first(where: { ($0.ownerEmail ?? "").lowercased() == owner && $0.isSelected })
    }

    private var recordsForActiveCar: [ServiceRecord] {
        guard let car = activeCar else { return [] }
        return allRecords.filter { $0.car == car }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(hex: "#1A1A40")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    aiPredictionsSection
                    alertsSection

                    Spacer().frame(height: 22)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear { loadAI() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { loadAI(force: true) } label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("AI & Alerts")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .cyan.opacity(0.5), radius: 10)
                .padding(.top, 22)

            if let car = activeCar {
                Text("\(car.name ?? "Car") • \(car.year ?? "—") • \(Int(car.mileage)) km")
                    .foregroundColor(.white.opacity(0.65))
                    .font(.subheadline)
            } else {
                Text("Select a car to see predictions and alerts.")
                    .foregroundColor(.white.opacity(0.65))
                    .font(.subheadline)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - AI Predictions

    private var aiPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔮 Smart AI Predictions")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                if isLoadingAI {
                    ProgressView().tint(.cyan)
                }
            }
            .padding(.horizontal, 20)

            if activeCar == nil {
                infoCard("No active car", "Go to car selection and choose an active car.")
                    .padding(.horizontal, 20)
            } else if recordsForActiveCar.isEmpty {
                infoCard("No service history", "Add at least one service record so AI can learn from your data.")
                    .padding(.horizontal, 20)
            } else if predictions.isEmpty {
                Text("Analyzing your car data…")
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 20)
            } else {
                ForEach(predictions) { pred in
                    predictionRow(pred)
                }
            }
        }
        .padding(.top, 8)
    }

    private func predictionRow(_ pred: MaintenancePrediction) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: iconForType(pred.type))
                    .foregroundColor(.cyan)

                Text(pred.type)
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()

                Text("\(Int(pred.confidence * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                    )
            }

            Text("Next service: \(format(pred.nextDate)) • ≈ \(Int(pred.nextMileage)) km")
                .foregroundColor(.white.opacity(0.75))
                .font(.subheadline)

            ProgressView(value: progress(for: pred))
                .tint(.cyan)

            Text(pred.basis == "history" ? "Based on your service history" : "Fallback estimate")
                .foregroundColor(.white.opacity(0.45))
                .font(.caption)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .shadow(color: .cyan.opacity(0.22), radius: 8)
        .padding(.horizontal, 20)
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        let items = allAlertsForActiveCar()

        return VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Maintenance Overview")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if activeCar == nil {
                infoCard("No active car", "Select a car to see maintenance alerts.")
                    .padding(.horizontal, 20)
            } else if items.isEmpty {
                Text("No maintenance tasks yet for this car.")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 20)
            } else {
                ForEach(items, id: \.objectID) { item in
                    alertRow(item)
                }
            }
        }
        .padding(.top, 10)
    }

    private func alertRow(_ item: MaintenanceItem) -> some View {
        let color = urgencyColor(for: item)

        return HStack(spacing: 12) {
            Circle().fill(color).frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title ?? "")
                    .foregroundColor(.white)

                Text("Next: \(format(item.nextChangeDate))")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.caption)
            }

            Spacer()

            Text(urgencyLabel(for: item))
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .shadow(color: color.opacity(0.25), radius: 6)
        .padding(.horizontal, 20)
    }

    // MARK: - load AI

    private func loadAI(force: Bool = false) {
        errorMessage = ""

        guard let car = activeCar else {
            predictions = []
            return
        }

        let carRecords = recordsForActiveCar
        guard !carRecords.isEmpty else {
            predictions = []
            return
        }

        if !force, !predictions.isEmpty { return }

        isLoadingAI = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: {
            predictions = AIMaintenanceEngine.shared.predictNextMaintenance(for: car, using: carRecords)
            isLoadingAI = false
        })
    }

    // MARK: - Alerts logic

    private func allAlertsForActiveCar() -> [MaintenanceItem] {
        guard let car = activeCar else { return [] }

        let carItems = allItems.filter { $0.car == car }

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let filtered = allowed.isEmpty ? carItems : carItems.filter { allowed.contains($0.title ?? "") }

        let unique = removeDuplicates(filtered)

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
            let title = (item.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            guard !title.isEmpty else { continue }

            if let existing = map[title] {
                if let d1 = item.nextChangeDate, let d2 = existing.nextChangeDate, d1 < d2 {
                    map[title] = item
                }
            } else {
                map[title] = item
            }
        }
        return Array(map.values)
    }

    private func daysUntil(_ date: Date?) -> Int {
        guard let date else { return 9999 }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let due = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: today, to: due).day ?? 9999
    }

    private func urgencyLevel(_ item: MaintenanceItem) -> Int {
        let d = daysUntil(item.nextChangeDate)
        switch d {
        case ..<0: return 0
        case 0...2: return 1
        case 3...7: return 2
        default: return 3
        }
    }

    private func urgencyLabel(for item: MaintenanceItem) -> String {
        let d = daysUntil(item.nextChangeDate)
        if d < 0 { return "overdue" }
        if d == 0 { return "today" }
        return "in \(d)d"
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
        let d = daysUntil(p.nextDate)
        let clamped = Swift.min(Swift.max(Double(d), 0), 60)
        return 1.0 - (clamped / 60.0)
    }

    private func iconForType(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("oil") { return "oil.drop.fill" }
        if t.contains("brake") { return "car.rear.waves.up" }
        if t.contains("battery") { return "bolt.car.fill" }
        if t.contains("tire") { return "circle.grid.cross" }
        if t.contains("fluid") { return "drop.fill" }
        if t.contains("inspect") || t.contains("filter") { return "aqi.medium" }
        return "wrench.and.screwdriver"
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func infoCard(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .foregroundColor(.white)
                .font(.headline)
            Text(subtitle)
                .foregroundColor(.white.opacity(0.65))
                .font(.subheadline)
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, y: 6)
    }
}

#Preview {
    NavigationStack {
        AIAlertsView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
