import SwiftUI
import CoreData

struct SmartMaintenanceView: View {
    @Environment(\.managedObjectContext) private var context

    @AppStorage("userEmail") private var userEmail: String = ""

    @FetchRequest(sortDescriptors: [], animation: .easeInOut)
    private var cars: FetchedResults<Car>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    )
    private var allRecords: FetchedResults<ServiceRecord>

    @State private var predictions: [MaintenancePrediction] = []
    @State private var isAnalyzing = false
    @State private var errorMessage: String = ""

    private var owner: String {
        userEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var activeCar: Car? {
        guard !owner.isEmpty else { return nil }
        return cars.first(where: { ($0.ownerEmail ?? "").lowercased() == owner && $0.isSelected })
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
                VStack(spacing: 20) {
                    Text("🔮 Smart Maintenance AI")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .glow(color: .cyan, radius: 10)
                        .padding(.top, 30)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    if activeCar == nil {
                        emptyState(
                            title: "No active car",
                            subtitle: "Select a car to get AI maintenance predictions."
                        )
                    } else {
                        carHeader

                        if isAnalyzing {
                            HStack(spacing: 10) {
                                ProgressView().tint(.cyan)
                                Text("Analyzing your car data…")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.top, 6)
                        }

                        if predictions.isEmpty && !isAnalyzing {
                            VStack(spacing: 10) {
                                Text("No predictions yet.")
                                    .foregroundColor(.white.opacity(0.75))

                                Text("Tap Analyze to generate predictions from service history.")
                                    .foregroundColor(.white.opacity(0.55))
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)

                                NeonButton(title: "Analyze") {
                                    analyzeData()
                                }
                                .padding(.horizontal, 70)
                                .padding(.top, 6)
                            }
                            .padding(.top, 10)
                        } else {
                            ForEach(predictions) { pred in
                                predictionCard(pred)
                                    .padding(.horizontal, 20)
                                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }

                            NeonButton(title: "Re-analyze") {
                                analyzeData()
                            }
                            .padding(.horizontal, 70)
                            .padding(.top, 10)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
        .onAppear {
            if activeCar != nil, !recordsForActiveCar.isEmpty {
                analyzeData()
            }
        }
    }

    private var carHeader: some View {
        VStack(spacing: 6) {
            Text(activeCar?.name ?? "Car")
                .foregroundColor(.white)
                .font(.title3.weight(.bold))

            Text("\(activeCar?.year ?? "—") • \(Int(activeCar?.mileage ?? 0)) km • \(recordsForActiveCar.count) services")
                .foregroundColor(.white.opacity(0.65))
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private func predictionCard(_ pred: MaintenancePrediction) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconForType(pred.type))
                    .foregroundColor(.cyan)
                    .font(.title3)

                Text(pred.type)
                    .font(.headline)
                    .foregroundColor(.white)

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

            Text("Next service: \(format(pred.nextDate)) • ≈ \(pred.nextMileage) km")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)

            ProgressView(value: progress(for: pred))
                .tint(.cyan)

            Text(pred.basis == "history" ? "Based on your service history" : "Fallback estimate")
                .foregroundColor(.white.opacity(0.5))
                .font(.caption)
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(16)
        .shadow(color: .cyan.opacity(0.25), radius: 8)
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 40)

            Text(title)
                .foregroundColor(.white)
                .font(.title3.weight(.bold))

            Text(subtitle)
                .foregroundColor(.white.opacity(0.65))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func analyzeData() {
        errorMessage = ""

        guard let car = activeCar else { return }
        guard !recordsForActiveCar.isEmpty else {
            predictions = []
            return
        }

        isAnalyzing = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15, execute: {
            predictions = AIMaintenanceEngine.shared.predictNextMaintenance(for: car, using: recordsForActiveCar)
            isAnalyzing = false
        })
    }

    private func progress(for prediction: MaintenancePrediction) -> Double {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: prediction.nextDate).day ?? 0
        return 1.0 - min(max(Double(days) / 60.0, 0.0), 1.0)
    }

    private func format(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func iconForType(_ type: String) -> String {
        switch type.lowercased() {
        case "oil": return "oil.drop.fill"
        case "brakes", "brake": return "car.rear.waves.up"
        case "battery": return "bolt.car.fill"
        case "tires", "tire": return "circle.grid.cross"
        case "fluids", "fluid": return "drop.fill"
        default: return "wrench.and.screwdriver"
        }
    }
}

#Preview {
    SmartMaintenanceView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
