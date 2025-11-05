import SwiftUI
import CoreData

struct SmartMaintenanceView: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: []) private var cars: FetchedResults<Car>
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)]) private var records: FetchedResults<ServiceRecord>

    @State private var predictions: [MaintenancePrediction] = []

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("🔮 Smart Maintenance AI")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .glow(color: .cyan, radius: 10)
                        .padding(.top, 30)

                    if predictions.isEmpty {
                        Text("Analyzing your car data…")
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                            .onAppear(perform: analyzeData)
                    } else {
                        ForEach(predictions) { pred in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: iconForType(pred.type))
                                        .foregroundColor(.cyan)
                                        .font(.title3)
                                    Text(pred.type)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Text("Next service: \(format(pred.nextDate)) • ≈ \(pred.nextMileage) km")
                                    .foregroundColor(.white.opacity(0.7))
                                    .font(.subheadline)

                                ProgressView(value: progress(for: pred))
                                    .tint(.cyan)
                            }
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(16)
                            .shadow(color: .cyan.opacity(0.4), radius: 8)
                            .padding(.horizontal, 20)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
        }
    }

    private func analyzeData() {
        guard let car = cars.first else { return }
        predictions = AIMaintenanceEngine.shared.predictNextMaintenance(for: car, using: Array(records))
    }

    private func progress(for prediction: MaintenancePrediction) -> Double {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: prediction.nextDate).day ?? 0
        return 1.0 - min(Double(days) / 30.0, 1.0)
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter(); f.dateStyle = .medium; return f.string(from: date)
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
}


#Preview {
    SmartMaintenanceView()
}
