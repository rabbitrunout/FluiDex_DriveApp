import SwiftUI
import CoreData
import Foundation


struct AIAlertsView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)])
    private var maintenance: FetchedResults<MaintenanceItem>

    @FetchRequest(sortDescriptors: [],
                  predicate: NSPredicate(format: "isSelected == true"))
    private var selectedCar: FetchedResults<Car>

    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)])
    private var records: FetchedResults<ServiceRecord>

    @State private var predictions: [MaintenancePrediction] = []

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {

                    Text("AI & Alerts")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.6), radius: 10)
                        .padding(.top, 20)

                    aiPredictionsSection
                    urgentAlertsSection
                }
            }
            .onAppear(perform: loadAI)
        }
    }

    // MARK: AI Predictions
    private var aiPredictionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔮 Smart AI Predictions")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if predictions.isEmpty {
                Text("Analyzing your car data…")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 20)
            } else {
                ForEach(predictions) { pred in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: iconForType(pred.type))
                                .foregroundColor(.cyan)
                            Text(pred.type)
                                .foregroundColor(.white)
                                .font(.headline)
                        }

                        Text("Next service: \(format(pred.nextDate)) • ≈ \(pred.nextMileage) km")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))

                        ProgressView(value: progress(for: pred))
                            .tint(.cyan)
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(16)
                    .shadow(color: .cyan.opacity(0.35), radius: 8)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: Urgent Alerts
    private var urgentAlertsSection: some View {
        let alerts = sortedUrgent(maintenance)

        return VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Maintenance Alerts")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)

            if alerts.isEmpty {
                Text("No alerts — everything looks good!")
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 20)
            } else {
                ForEach(alerts) { item in
                    HStack {
                        Circle()
                            .fill(colorForDate(item.nextChangeDate))
                            .frame(width: 12, height: 12)

                        VStack(alignment: .leading) {
                            Text(item.title ?? "")
                                .foregroundColor(.white)
                            Text("Next: \(format(item.nextChangeDate))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .cornerRadius(16)
                    .shadow(color: colorForDate(item.nextChangeDate).opacity(0.4), radius: 6)
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: Helpers

    private func loadAI() {
        guard let car = selectedCar.first else { return }
        predictions = AIMaintenanceEngine.shared.predictNextMaintenance(for: car, using: Array(records))
    }

    private func progress(for p: MaintenancePrediction) -> Double {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: p.nextDate).day ?? 0
        return 1.0 - min(Double(days) / 30.0, 1.0)
    }

    private func sortedUrgent(_ list: FetchedResults<MaintenanceItem>) -> [MaintenanceItem] {
        list.sorted {
            urgencyLevel($0) < urgencyLevel($1)
        }
    }

    private func urgencyLevel(_ item: MaintenanceItem) -> Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.nextChangeDate ?? Date()).day ?? 999

        switch days {
        case ..<0: return 0     // 🔥 overdue
        case 0...2: return 1    // 🟠 urgent
        case 3...7: return 2    // 🟡 soon
        default: return 3       // 🟢 fine
        }
    }

    private func colorForDate(_ date: Date?) -> Color {
        guard let date else { return .gray }

        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        switch days {
        case ..<0: return .red
        case 0...2: return .orange
        case 3...7: return .yellow
        default: return .green
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "oil": return "oil.drop.fill"
        case "brake": return "car.rear.waves.up"
        case "battery": return "bolt.car.fill"
        case "tire": return "circle.grid.cross"
        default: return "wrench.and.screwdriver"
        }
    }

    private func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter(); f.dateStyle = .medium
        return f.string(from: date)
    }
}


#Preview {
    AIAlertsView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
