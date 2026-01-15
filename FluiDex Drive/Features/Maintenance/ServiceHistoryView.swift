import SwiftUI
import CoreData

struct ServiceHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("userEmail") private var currentUserEmail: String = ""

    @State private var recordToEdit: ServiceRecord? = nil

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true AND ownerEmail == %@", (UserDefaults.standard.string(forKey: "userEmail") ?? "").lowercased())
    ) private var selectedCar: FetchedResults<Car>

    private var activeCar: Car? { selectedCar.first }

    private var recordsForCar: [ServiceRecord] {
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

            VStack(spacing: 14) {
                Text("Service History")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.top, 16)

                if activeCar == nil {
                    Text("No car selected.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 30)
                    Spacer()
                } else if recordsForCar.isEmpty {
                    Text("No service records yet.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 30)
                    Spacer()
                } else {
                    List {
                        ForEach(recordsForCar, id: \.objectID) { r in
                            Button {
                                recordToEdit = r
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: iconForType(r.type ?? "Other"))
                                        .foregroundColor(.yellow)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(r.type ?? "Service")
                                            .foregroundColor(.white)
                                            .font(.headline)

                                        Text("\(Int(r.mileage)) km • \(formatDate(r.date))")
                                            .foregroundColor(.white.opacity(0.65))
                                            .font(.caption)
                                    }

                                    Spacer()

                                    Text("$\(r.totalCost, specifier: "%.2f")")
                                        .foregroundColor(Color(hex: "#FFD54F"))
                                        .font(.subheadline.weight(.semibold))
                                }
                                .padding(.vertical, 8)
                            }
                            .listRowBackground(Color.white.opacity(0.06))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    delete(r)
                                } label: { Label("Delete", systemImage: "trash") }

                                Button {
                                    recordToEdit = r
                                } label: { Label("Edit", systemImage: "pencil") }
                                .tint(.cyan)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .sheet(item: $recordToEdit) { rec in
            EditServiceView(record: rec)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func delete(_ r: ServiceRecord) {
        viewContext.delete(r)
        try? viewContext.save()
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
        case "Tires": return "circle.grid.cross.fill"
        default: return "wrench.and.screwdriver"
        }
    }
}
