import SwiftUI
import CoreData

struct EditServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    let record: ServiceRecord

    @State private var mileage: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    @State private var costParts: String = ""
    @State private var costLabor: String = ""
    @State private var totalCost: Double = 0

    @State private var errorMessage: String = ""
    @State private var showDeleteConfirm = false

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

                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Service")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(22)
                    }
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
        .confirmationDialog(
            "Delete this service record?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteRecord() }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    // MARK: - Maintenance Recalc (shared logic)

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

    private func maintenanceMatches(serviceKey: String, item: MaintenanceItem) -> Bool {
        let title = (item.title ?? "").lowercased()
        let cat = (item.category ?? "").lowercased()

        switch serviceKey {
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
    }

    /// Важно: после EDIT и после DELETE мы делаем одну и ту же операцию:
    /// находим последнюю запись данного типа → обновляем last/next у MaintenanceItem
    private func recomputeMaintenance(for car: Car, serviceType: String) {
        let key = normalizeServiceKey(serviceType)
        guard key != "other" else { return }

        // 1) maintenance items этой машины
        let miReq: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        miReq.predicate = NSPredicate(format: "car == %@", car)
        let items = (try? viewContext.fetch(miReq)) ?? []
        let matchedItems = items.filter { maintenanceMatches(serviceKey: key, item: $0) }
        if matchedItems.isEmpty { return }

        // 2) все сервисы этой машины, сорт по дате
        let srReq: NSFetchRequest<ServiceRecord> = ServiceRecord.fetchRequest()
        srReq.predicate = NSPredicate(format: "car == %@", car)
        srReq.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)]
        let records = (try? viewContext.fetch(srReq)) ?? []

        // 3) последняя запись данного типа
        let latestSameType = records.first(where: { normalizeServiceKey($0.type ?? "") == key })

        for item in matchedItems {
            if let last = latestSameType {
                item.lastChangeDate = last.date
                item.lastChangeMileage = last.mileage

                if item.intervalKm > 0 {
                    item.nextChangeMileage = last.mileage + item.intervalKm
                } else {
                    item.nextChangeMileage = 0
                }

                if item.intervalDays > 0, let d = last.date {
                    item.nextChangeDate = Calendar.current.date(byAdding: .day, value: Int(item.intervalDays), to: d)
                } else if let d = last.date {
                    item.nextChangeDate = Calendar.current.date(byAdding: .day, value: 180, to: d)
                }
            } else {
                // если сервисов этого типа больше нет
                item.lastChangeDate = nil
                item.lastChangeMileage = 0
                // next можно оставить как было, чтобы не «пустело»
            }
        }

        try? viewContext.save()
    }

    // MARK: - Next Service defaults for Dashboard card

    private func applyNextServiceDefaults(
        to record: ServiceRecord,
        using item: MaintenanceItem?,
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

    private func fetchMatchedMaintenanceItem(for car: Car, serviceType: String) -> MaintenanceItem? {
        let key = normalizeServiceKey(serviceType)
        guard key != "other" else { return nil }

        let req: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        req.predicate = NSPredicate(format: "car == %@", car)

        let list = (try? viewContext.fetch(req)) ?? []
        return list.first(where: { maintenanceMatches(serviceKey: key, item: $0) })
    }

    // MARK: - Save

    private func save() {
        errorMessage = ""

        let newMileage = Int32(mileage) ?? record.mileage
        let newDate = date
        let type = record.type ?? "Other"

        record.mileage = newMileage
        record.date = newDate
        record.note = note
        record.costParts = Double(costParts) ?? 0
        record.costLabor = Double(costLabor) ?? 0
        record.totalCost = totalCost

        // ✅ пересчёт nextService* для Dashboard
        if let car = record.car {
            let matched = fetchMatchedMaintenanceItem(for: car, serviceType: type)
            applyNextServiceDefaults(to: record, using: matched, mileage: newMileage, date: newDate)
        } else {
            record.nextServiceKm = newMileage + 10000
            record.nextServiceDate = Calendar.current.date(byAdding: .day, value: 180, to: newDate)
        }

        do {
            try viewContext.save()

            // ✅ пересчёт maintenance items (масло/тормоза и т.д.)
            if let car = record.car {
                recomputeMaintenance(for: car, serviceType: type)
            }

            FirebaseSyncManager.shared.syncServiceRecord(record)
            dismiss()
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete

    private func deleteRecord() {
        errorMessage = ""

        let type = record.type ?? "Other"
        let car = record.car

        viewContext.delete(record)

        do {
            try viewContext.save()

            if let car {
                recomputeMaintenance(for: car, serviceType: type)
            }

            dismiss()
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }
}
