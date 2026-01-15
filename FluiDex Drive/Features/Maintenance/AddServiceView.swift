import SwiftUI
import CoreData

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility

    @AppStorage("userEmail") private var currentUserEmail: String = ""   // ✅ NEW

    @State private var serviceType: String
    @State private var mileage: String
    @State private var date: Date

    @State private var note: String = ""
    @State private var costParts: String = ""
    @State private var costLabor: String = ""
    @State private var totalCost: Double = 0
    @State private var showDatePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String = ""                         // ✅ NEW

    // optional связь с MaintenanceItem
    private let maintenanceItemID: NSManagedObjectID?

    let serviceTypes = ["Oil", "Tires", "Fluids", "Battery", "Brakes", "Inspection", "Other"]

    init(
        prefilledType: String? = nil,
        prefilledMileage: Int32? = nil,
        prefilledDate: Date? = nil,
        maintenanceItemID: NSManagedObjectID? = nil
    ) {
        _serviceType = State(initialValue: prefilledType ?? "Oil")
        _mileage = State(initialValue: String(prefilledMileage ?? 0))
        _date = State(initialValue: prefilledDate ?? Date())
        self.maintenanceItemID = maintenanceItemID
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
                VStack(spacing: 25) {
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
                        .onChange(of: costParts) { _, _ in recalcTotal() }
                        .padding(.horizontal)

                    glowingField("Labor Cost ($)", text: $costLabor, icon: "hammer.fill")
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
        .onAppear { withAnimation { tabBar.isVisible = false } }
        .onDisappear { withAnimation { tabBar.isVisible = true } }
    }

    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    // ✅ fetch current user
    private func fetchCurrentUser() -> User? {
        let owner = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !owner.isEmpty else { return nil }

        let req: NSFetchRequest<User> = User.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "email == %@", owner)
        return try? viewContext.fetch(req).first
    }

    // ✅ fetch active car ONLY for current owner
    private func fetchActiveCarForOwner() -> Car? {
        let owner = currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !owner.isEmpty else { return nil }

        let req: NSFetchRequest<Car> = Car.fetchRequest()
        req.fetchLimit = 1
        req.predicate = NSPredicate(format: "isSelected == true AND ownerEmail == %@", owner)
        return try? viewContext.fetch(req).first
    }

    private func saveService() {
        errorMessage = ""
        isSaving = true

        defer { isSaving = false }

        let enteredMileage = Int32(mileage) ?? 0

        guard let activeCar = fetchActiveCarForOwner() else {
            errorMessage = "No active car for this account. Please select a car first."
            return
        }

        guard let currentUser = fetchCurrentUser() else {
            errorMessage = "User session not found. Please log in again."
            return
        }

        // 1) создаём ServiceRecord
        let newRecord = ServiceRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.type = serviceType
        newRecord.mileage = enteredMileage
        newRecord.date = date
        newRecord.note = note

        // next service defaults
        newRecord.nextServiceKm = enteredMileage + 10000
        newRecord.nextServiceDate = Calendar.current.date(byAdding: .day, value: 180, to: date)

        // ✅ attach relations
        newRecord.car = activeCar
        newRecord.user = currentUser   // ✅ IMPORTANT (по модели User.services)

        // 2) если пришли из schedule → обновляем конкретный MaintenanceItem
        if let id = maintenanceItemID,
           let item = try? viewContext.existingObject(with: id) as? MaintenanceItem {

            // ✅ safety: обновляем только если item принадлежит активной машине
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
