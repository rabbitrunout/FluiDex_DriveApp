import SwiftUI
import CoreData

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility

    @State private var serviceType = "Oil"
    @State private var mileage = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var costParts = ""
    @State private var costLabor = ""
    @State private var totalCost: Double = 0
    @State private var showDatePicker = false
    @State private var isSaving = false

    // ✅ новый sheet для полного выбора
    @State private var showServiceTypeSheet = false

    let serviceTypes = ["Oil", "Tires", "Fluids", "Battery", "Brakes", "Inspection", "Other"]

    var body: some View {
        ZStack {
            // 🌌 Неоновый фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {

                    // 🏁 Заголовок
                    Text("Add New Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                        .padding(.top, 20)

                    // ✅ НОВЫЙ БЛОК: Service Type (chips + sheet)
                    serviceTypeChips
                        .padding(.horizontal)

                    // 🚘 Пробег
                    glowingField("Mileage (km)", text: $mileage, icon: "speedometer")
                        .keyboardType(.numberPad)
                        .padding(.horizontal)

                    // 📅 Дата с авто-сворачиванием
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
                                .accentColor(Color(hex: "#FFD54F"))
                                .tint(Color(hex: "#FFD54F"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                )
                                .environment(\.colorScheme, .dark)
                                .scrollContentBackground(.hidden)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color(hex: "#1A1A40").opacity(0.95),
                                            Color.black.opacity(0.8)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .cornerRadius(16)
                                    .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
                                )
                                .onChange(of: date) {
                                    withAnimation(.spring()) { showDatePicker = false }
                                }
                                .transition(.opacity.combined(with: .slide))
                                .padding(.horizontal, 10)
                        }
                    }
                    .padding(.horizontal)

                    // 💵 Стоимость
                    glowingField("Parts Cost ($)", text: $costParts, icon: "wrench.fill")
                        .onChange(of: costParts) { recalcTotal() }
                        .padding(.horizontal)

                    glowingField("Labor Cost ($)", text: $costLabor, icon: "hammer.fill")
                        .onChange(of: costLabor) { recalcTotal() }
                        .padding(.horizontal)

                    // 💰 Итого
                    HStack {
                        Text("Total: ")
                            .foregroundColor(.white)
                        Spacer()
                        Text("$\(totalCost, specifier: "%.2f")")
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .bold()
                    }
                    .padding(.horizontal, 40)

                    // 📝 Заметка
                    glowingField("Note (optional)", text: $note, icon: "pencil")
                        .padding(.horizontal)

                    // 💾 Save
                    Button {
                        saveService()
                    } label: {
                        HStack {
                            Image(systemName: isSaving ? "hourglass" : "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .bold))
                                .rotationEffect(.degrees(isSaving ? 360 : 0))
                                .animation(isSaving ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSaving)

                            Text(isSaving ? "Saving..." : "Save Service")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(30)
                        .shadow(color: Color.yellow.opacity(0.4), radius: 10, y: 6)
                        .scaleEffect(isSaving ? 0.95 : 1.0)
                        .animation(.spring(), value: isSaving)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear { withAnimation { tabBar.isVisible = false } }
        .onDisappear { withAnimation { tabBar.isVisible = true } }
        .sheet(isPresented: $showServiceTypeSheet) {
            serviceTypePickerSheet
        }
    }

    // MARK: - ✅ Chips (все названия видны + тап откроет sheet)
    private var serviceTypeChips: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(Color(hex: "#FFD54F"))

                Text("Service Type")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.headline)

                Spacer()

                // кнопка "All" (удобно для полного выбора)
                Button {
                    showServiceTypeSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text(serviceType)
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)

                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(serviceTypes, id: \.self) { type in
                        Button {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                serviceType = type
                            }
                        } label: {
                            Text(type)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(type == serviceType ? .black : .white.opacity(0.9))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false) // ✅ не обрезает текст
                                .padding(.vertical, 10)
                                .padding(.horizontal, 14)
                                .background(
                                    type == serviceType
                                    ? Color(hex: "#FFD54F")
                                    : Color.white.opacity(0.08)
                                )
                                .cornerRadius(18)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(Color.cyan.opacity(type == serviceType ? 0.0 : 0.35), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 6)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.white.opacity(0.06))
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
            )
        }
    }

    // MARK: - ✅ Sheet со всем списком (все названия 100% видны)
    private var serviceTypePickerSheet: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                List {
                    ForEach(serviceTypes, id: \.self) { type in
                        Button {
                            serviceType = type
                            showServiceTypeSheet = false
                        } label: {
                            HStack {
                                Text(type)
                                    .foregroundColor(.white)

                                Spacer()

                                if type == serviceType {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Color(hex: "#FFD54F"))
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.06))
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Service Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showServiceTypeSheet = false }
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - 💰 Total
    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    // MARK: - 💾 Save
    private func saveService() {
        let newRecord = ServiceRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.type = serviceType
        newRecord.mileage = Int32(mileage) ?? 0
        newRecord.date = date
        newRecord.note = note
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
    }
}

#Preview {
    AddServiceView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TabBarVisibility())
}
