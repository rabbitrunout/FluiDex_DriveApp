import SwiftUI
import CoreData

struct EditServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let record: ServiceRecord

    // (опционально) если открываем edit из Maintenance Schedule и знаем, какой item связан
    private let maintenanceItemID: NSManagedObjectID?

    @State private var mileage: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var costParts: String = ""
    @State private var costLabor: String = ""
    @State private var totalCost: Double = 0

    @State private var errorMessage: String = ""

    init(record: ServiceRecord, maintenanceItemID: NSManagedObjectID? = nil) {
        self.record = record
        self.maintenanceItemID = maintenanceItemID
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Edit Service")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    Text(record.type ?? "Service")
                        .foregroundColor(Color(hex: "#FFD54F"))
                        .font(.headline)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    glowingField("Mileage (km)", text: $mileage, icon: "speedometer")
                        .keyboardType(.numberPad)
                        .padding(.horizontal)
                        .onChange(of: mileage) { _, _ in
                            // можно пересчитывать total/preview, если захочешь
                        }

                    DatePicker("Date", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .padding(.horizontal)

                    glowingField("Parts Cost ($)", text: $costParts, icon: "wrench.fill")
                        .keyboardType(.decimalPad)
                        .onChange(of: costParts) { _, _ in recalcTotal() }
                        .padding(.horizontal)

                    glowingField("Labor Cost ($)", text: $costLabor, icon: "hammer.fill")
                        .keyboardType(.decimalPad)
                        .onChange(of: costLabor) { _, _ in recalcTotal() }
                        .padding(.horizontal)

                    HStack {
                        Text("Total:")
                            .foregroundColor(.white)
                        Spacer()
                        Text("$\(totalCost, specifier: "%.2f")")
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .bold()
                    }
                    .padding(.horizontal, 40)

                    glowingField("Note (optional)", text: $note, icon: "pencil")
                        .padding(.horizontal)

                    Button("Save Changes") {
                        save()
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FFD54F"))
                    .cornerRadius(30)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            mileage = String(record.mileage)
            date = record.date ?? Date()
            note = record.note ?? ""
            costParts = String(format: "%.2f", record.costParts)
            costLabor = String(format: "%.2f", record.costLabor)
            totalCost = record.totalCost
        }
    }

    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    // MARK: - helpers (как в AddServiceView)

    private func normalizeServiceKey(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("oil") { return "oil" }
        if t.contains("brake") { return "brake" }
        if t.contains("battery") { return "battery" }
        if t.contains("fluid") { return "fluid" }
        if t.contains("tire") { return "tire" }
        if t.contains("inspect") { return "inspect" }
        return "other"
    }

    private func fetchMaintenanceItemForCar(_ car: Car, serviceType: String) -> MaintenanceItem? {
        let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        req.predicate = NSPredicate(format: "car == %@", car)

        let list = (try? viewContext.fetch(req)) ?? []
        if list.isEmpty { return nil }

        let key = normalizeServiceKey(serviceType)

        return list.first(where: { item in
            let title = (item.title ?? "").lowercased()
            let cat = (item.category ?? "").lowercased()

            switch key {
            case "oil": return title.contains("oil") || cat.contains("oil")
            case "brake": return title.contains("brake") || cat.contains("brake")
            case "battery": return title.contains("battery") || cat.contains("battery")
            case "fluid": return title.contains("fluid") || cat.contains("fluid")
            case "tire": return title.contains("tire") || cat.contains("tire")
            case "inspect":
                return title.contains("inspect") || title.contains("filter")
                    || cat.contains("inspect") || cat.contains("filter")
            default:
                return false
            }
        })
    }

    private func applyNextServiceDefaults(
        to record: ServiceRecord,
        from item: MaintenanceItem?,
        mileage: Int32,
        date: Date
    ) {
        if let item {
            record.nextServiceKm = item.intervalKm > 0 ? (mileage + item.intervalKm) : (mileage + 10000)
            record.nextServiceDate = item.intervalDays > 0
                ? Calendar.current.date(byAdding: .day, value: Int(item.intervalDays), to: date)
                : Calendar.current.date(byAdding: .day, value: 180, to: date)
        } else {
            record.nextServiceKm = mileage + 10000
            record.nextServiceDate = Calendar.current.date(byAdding: .day, value: 180, to: date)
        }
    }

    // MARK: - save (FIX)

    private func save() {
        errorMessage = ""

        let newMileage = Int32(mileage) ?? record.mileage
        let newDate = date

        record.mileage = newMileage
        record.date = newDate
        record.note = note
        record.costParts = Double(costParts) ?? 0
        record.costLabor = Double(costLabor) ?? 0
        record.totalCost = totalCost

        // ✅ ОБЯЗАТЕЛЬНО пересчитываем nextService
        let serviceType = record.type ?? "Other"

        if let car = record.car {
            // 1) если пришёл конкретный maintenanceItemID — используем его
            var matched: MaintenanceItem? = nil

            if let mid = maintenanceItemID,
               let item = try? viewContext.existingObject(with: mid) as? MaintenanceItem,
               item.car == car {
                matched = item
            } else {
                // 2) иначе ищем подходящий maintenance item по типу
                matched = fetchMaintenanceItemForCar(car, serviceType: serviceType)
            }

            applyNextServiceDefaults(to: record, from: matched, mileage: newMileage, date: newDate)

            // ✅ (опционально) если есть maintenanceItemID — обновляем и его
            if let mid = maintenanceItemID,
               let item = try? viewContext.existingObject(with: mid) as? MaintenanceItem,
               item.car == car {

                item.lastChangeDate = newDate
                item.lastChangeMileage = newMileage

                if item.intervalKm > 0 { item.nextChangeMileage = newMileage + item.intervalKm }
                if item.intervalDays > 0 {
                    item.nextChangeDate = Calendar.current.date(byAdding: .day, value: Int(item.intervalDays), to: newDate)
                }
            }
        } else {
            // fallback
            record.nextServiceKm = newMileage + 10000
            record.nextServiceDate = Calendar.current.date(byAdding: .day, value: 180, to: newDate)
        }

        do {
            try viewContext.save()
            FirebaseSyncManager.shared.syncServiceRecord(record)
            dismiss()
        } catch {
            errorMessage = "Error saving: \(error.localizedDescription)"
            print("❌ EditService save error:", error)
        }
    }
}
