import SwiftUI
import CoreData

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility

    // ✅ State должны инициализироваться через _state = State(...)
    @State private var serviceType: String
    @State private var mileage: String
    @State private var date: Date

    @State private var note = ""
    @State private var costParts = ""
    @State private var costLabor = ""
    @State private var totalCost: Double = 0
    @State private var showDatePicker = false
    @State private var isSaving = false

    let serviceTypes = ["Oil", "Tires", "Fluids", "Battery", "Brakes", "Inspection", "Other"]

    // ✅ Prefill (из Dashboard)
    private let prefilledType: String?
    private let prefilledMileage: Int32?
    private let prefilledDate: Date?

    init(prefilledType: String? = nil, prefilledMileage: Int32? = nil, prefilledDate: Date? = nil) {
        self.prefilledType = prefilledType
        self.prefilledMileage = prefilledMileage
        self.prefilledDate = prefilledDate

        _serviceType = State(initialValue: prefilledType ?? "Oil")
        _mileage = State(initialValue: prefilledMileage.map { String($0) } ?? "")
        _date = State(initialValue: prefilledDate ?? Date())
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

                    // тип сервиса (твоя функция)
                    glowingPicker(
                        "Service Type",
                        selection: $serviceType,
                        options: serviceTypes,
                        icon: "gearshape.fill"
                    )
                    .padding(.horizontal)

                    glowingField("Mileage (km)", text: $mileage, icon: "speedometer")
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    // Date
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
                                .transition(.opacity.combined(with: .slide))
                                .padding(.horizontal, 10)
                        }
                    }
                    .padding(.horizontal)

                    // Costs
                    glowingField("Parts Cost ($)", text: $costParts, icon: "wrench.fill")
                        .onChange(of: costParts) { _, _ in recalcTotal() }
                        .padding(.horizontal)

                    glowingField("Labor Cost ($)", text: $costLabor, icon: "hammer.fill")
                        .onChange(of: costLabor) { _, _ in recalcTotal() }
                        .padding(.horizontal)

                    HStack {
                        Text("Total: ")
                            .foregroundColor(.white)
                        Spacer()
                        Text("$\(totalCost, specifier: "%.2f")")
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .bold()
                    }
                    .padding(.horizontal, 40)

                    glowingField("Note (optional)", text: $note, icon: "pencil")
                        .padding(.horizontal)

                    // Save
                    Button {
                        saveService()
                    } label: {
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
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            withAnimation { tabBar.isVisible = false }
            recalcTotal()
        }
        .onDisappear { withAnimation { tabBar.isVisible = true } }
    }

    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    private func saveService() {
        isSaving = true

        let newRecord = ServiceRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.type = serviceType
        newRecord.mileage = Int32(mileage) ?? 0
        newRecord.date = date
        newRecord.note = note

        // TODO: можно связать это с MaintenanceRules позже
        newRecord.nextServiceKm = Int32((Int(mileage) ?? 0) + 10000)
        newRecord.nextServiceDate = Calendar.current.date(byAdding: .day, value: 180, to: date)

        let fetch: NSFetchRequest<Car> = Car.fetchRequest()
        fetch.predicate = NSPredicate(format: "isSelected == true")
        if let activeCar = try? viewContext.fetch(fetch).first {
            newRecord.car = activeCar
        }

        do {
            try viewContext.save()
            FirebaseSyncManager.shared.syncServiceRecord(newRecord)
            dismiss()
        } catch {
            print("❌ Error saving service: \(error.localizedDescription)")
        }

        isSaving = false
    }
}

#Preview {
    AddServiceView(prefilledType: "Oil", prefilledMileage: 40000, prefilledDate: .now)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TabBarVisibility())
}
