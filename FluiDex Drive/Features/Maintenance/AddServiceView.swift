import SwiftUI
import CoreData

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility

    @AppStorage("userEmail") private var currentUserEmail: String = ""

    @State private var serviceType: String
    @State private var mileage: String
    @State private var date: Date

    // ✅ Next due preview
    @State private var nextDueKmPreview: Int32 = 0
    @State private var nextDueDatePreview: Date? = nil
    @State private var previewInfoText: String = ""

    @State private var note: String = ""
    @State private var costParts: String = ""
    @State private var costLabor: String = ""
    @State private var totalCost: Double = 0
    @State private var showDatePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String = ""

    // optional связь с MaintenanceItem
    private let maintenanceItemID: NSManagedObjectID?

    // ✅ if type was prefilled (from schedule quick log) -> lock it
    private let isTypeLocked: Bool

    // ✅ IMPORTANT: exact car passed from ServiceHistoryView
    private let carObjectID: NSManagedObjectID?

    let serviceTypes = ["Oil", "Tires", "Fluids", "Battery", "Brakes", "Inspection", "Other"]

    init(
        prefilledType: String? = nil,
        prefilledMileage: Int32? = nil,
        prefilledDate: Date? = nil,
        maintenanceItemID: NSManagedObjectID? = nil,
        carObjectID: NSManagedObjectID? = nil
    ) {
        _serviceType = State(initialValue: prefilledType ?? "Oil")
        _mileage = State(initialValue: String(prefilledMileage ?? 0))
        _date = State(initialValue: prefilledDate ?? Date())
        self.maintenanceItemID = maintenanceItemID
        self.isTypeLocked = (prefilledType != nil)
        self.carObjectID = carObjectID
    }

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Text("Add New Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                        .padding(.top, 20)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // ✅ Service Type
                    serviceTypeRow
                        .padding(.horizontal)

                    // mileage
                    glowingField("Mileage (km)", text: $mileage, icon: "speedometer")
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    // date
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        Button {
                            withAnimation(.spring()) { showDatePicker.toggle() }
                        } label: {
                            HStack {
                                Text(date.formatted(date: .abbreviated, time: .omitted))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundColor(Color(hex: "#FFD54F"))
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                            )
                        }

                        if showDatePicker {
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .tint(Color(hex: "#FFD54F"))
                                .onChange(of: date) { _, _ in
                                    withAnimation(.spring()) { showDatePicker = false }
                                }
                                .padding(.horizontal, 10)
                        }
                    }
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

                    // ✅ Next due preview
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.cyan)

                        Text(previewInfoText.isEmpty ? "Next due —" : previewInfoText)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.footnote)

                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 4)

                    glowingField("Note (optional)", text: $note, icon: "pencil")
                        .padding(.horizontal)

                    Button { saveService() } label: {
                        HStack {
                            Image(systemName: isSaving ? "hourglass" : "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                            Text(isSaving ? "Saving..." : "Save Service")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(30)
                        .shadow(color: Color.yellow.opacity(0.4), radius: 10, y: 6)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation { tabBar.isVisible = false }
            recalcTotal()
            refreshNextDuePreview()
        }
        .onDisappear { withAnimation { tabBar.isVisible = true } }
        .onChange(of: serviceType) { _, _ in refreshNextDuePreview() }
        .onChange(of: mileage) { _, _ in refreshNextDuePreview() }
        .onChange(of: date) { _, _ in refreshNextDuePreview() }
    }

    // MARK: - UI piece
    private var serviceTypeRow: some View {
        Group {
            if isTypeLocked {
                HStack(spacing: 12) {
                    Image(systemName: "tag.fill")
                        .foregroundColor(Color(hex: "#FFD54F"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Service Type")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(serviceType)
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.45))
                }
                .padding()
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                )
            } else {
                Menu {
                    ForEach(serviceTypes, id: \.self) { t in
                        Button { serviceType = t } label: { Text(t) }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "tag.fill")
                            .foregroundColor(Color(hex: "#FFD54F"))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Service Type")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                            Text(serviceType)
                                .font(.headline)
                                .foregroundColor(.white)
                        }

                        Spacer()

                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                    )
                }
            }
        }
    }

    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    // MARK: - Formatting for preview

    private func formatDateShort(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func formatKm(_ km: Int32) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: km)) ?? "\(km)"
    }

    // MARK: - Fetch helpers

    private func fetchCurrentUser() -> User? {
        let owner = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !owner.isEmpty else { return nil }

        let req: NSFetchRequest<User> = User.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "email == %@", owner)
        return try? viewContext.fetch(req).first
    }

    /// ✅ STRICT: always save to the exact car passed from ServiceHistoryView.
    /// If carObjectID is missing -> do NOT guess (prevents mixing cars).
    private func fetchCarForSaving() -> Car? {
        guard let id = carObjectID,
              let car = try? viewContext.existingObject(with: id) as? Car else {
            return nil
        }
        return car
    }

    // MARK: - Maintenance lookup helpers

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

    private func fetchMaintenanceItemForActiveCar(_ car: Car, serviceType: String) -> MaintenanceItem? {
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
                return title.contains("inspect") || title.contains("filter") ||
                       cat.contains("inspect") || cat.contains("filter")
            default: return false
            }
        })
    }

    private func computeNextDue(using item: MaintenanceItem?, mileage: Int32, date: Date) -> (km: Int32, nextDate: Date?, source: String) {
        if let item {
            let km = item.intervalKm > 0 ? mileage + item.intervalKm : mileage + 10000
            let d = item.intervalDays > 0
            ? Calendar.current.date(byAdding: .day, value: Int(item.intervalDays), to: date)
            : Calendar.current.date(byAdding: .day, value: 180, to: date)

            return (km, d, "from schedule")
        } else {
            let km = mileage + 10000
            let d = Calendar.current.date(byAdding: .day, value: 180, to: date)
            return (km, d, "default")
        }
    }

    private func refreshNextDuePreview() {
        guard let activeCar = fetchCarForSaving() else {
            nextDueKmPreview = 0
            nextDueDatePreview = nil
            previewInfoText = "Open Service History for a specific car to add records."
            return
        }

        let enteredMileage = Int32(mileage) ?? 0
        var matched: MaintenanceItem? = nil

        if let id = maintenanceItemID,
           let item = try? viewContext.existingObject(with: id) as? MaintenanceItem,
           item.car == activeCar {
            matched = item
        } else {
            matched = fetchMaintenanceItemForActiveCar(activeCar, serviceType: serviceType)
        }

        let next = computeNextDue(using: matched, mileage: enteredMileage, date: date)

        nextDueKmPreview = next.km
        nextDueDatePreview = next.nextDate
        previewInfoText = "Next due: \(formatKm(next.km)) km • \(formatDateShort(next.nextDate)) (\(next.source))"
    }

    private func saveService() {
        errorMessage = ""
        isSaving = true
        defer { isSaving = false }

        let enteredMileage = Int32(mileage) ?? 0

        // ✅ STRICT car binding
        guard let activeCar = fetchCarForSaving() else {
            errorMessage = "No car selected. Open Service History for a car and try again."
            return
        }

        guard let currentUser = fetchCurrentUser() else {
            errorMessage = "User session not found. Please log in again."
            return
        }

        refreshNextDuePreview()

        let newRecord = ServiceRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.type = serviceType
        newRecord.mileage = enteredMileage
        newRecord.date = date
        newRecord.note = note

        newRecord.costParts = Double(costParts) ?? 0
        newRecord.costLabor = Double(costLabor) ?? 0
        newRecord.totalCost = totalCost

        newRecord.nextServiceKm = nextDueKmPreview > 0 ? nextDueKmPreview : (enteredMileage + 10000)
        newRecord.nextServiceDate = nextDueDatePreview ?? Calendar.current.date(byAdding: .day, value: 180, to: date)

        // ✅ bind to car (NOT guessed)
        newRecord.car = activeCar
        newRecord.user = currentUser

        // ✅ if from schedule -> update that MaintenanceItem
        if let id = maintenanceItemID,
           let item = try? viewContext.existingObject(with: id) as? MaintenanceItem {

            if item.car != activeCar {
                errorMessage = "This maintenance item belongs to another car. Please open schedule for the current car."
                return
            }

            item.lastChangeDate = date
            item.lastChangeMileage = enteredMileage

            let kmInterval = item.intervalKm
            let daysInterval = item.intervalDays

            if kmInterval > 0 {
                item.nextChangeMileage = enteredMileage + kmInterval
            }

            if daysInterval > 0 {
                item.nextChangeDate = Calendar.current.date(byAdding: .day, value: Int(daysInterval), to: date)
            } else {
                item.nextChangeDate = Calendar.current.date(byAdding: .day, value: 180, to: date)
            }
        }

        do {
            try viewContext.save()
            FirebaseSyncManager.shared.syncServiceRecord(newRecord)
            dismiss()
        } catch {
            errorMessage = "Error saving service: \(error.localizedDescription)"
            print("❌ Error saving service:", error)
        }
    }
}

#Preview {
    AddServiceView(prefilledType: "Oil", prefilledMileage: 40000, prefilledDate: .now)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TabBarVisibility())
}
