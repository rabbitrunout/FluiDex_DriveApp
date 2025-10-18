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

                    // 🔧 Тип сервиса
                    glowingPicker(
                        "Service Type",
                        selection: $serviceType,
                        options: serviceTypes,
                        icon: "gearshape.fill"
                    )
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
                                .colorScheme(.dark) // 👈 принудительно тёмный стиль
                                .accentColor(Color(hex: "#FFD54F")) // подсветка выбора
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

                    // 💵 Стоимость запчастей и работы
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

                    // 💾 Кнопка сохранения
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
    }

    // MARK: - 💰 Подсчет суммы
    private func recalcTotal() {
        totalCost = (Double(costParts) ?? 0) + (Double(costLabor) ?? 0)
    }

    // MARK: - 💾 Сохранение записи
    private func saveService() {
        isSaving = true
        let newRecord = ServiceRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.type = serviceType
        newRecord.mileage = Int32(mileage) ?? 0
        newRecord.date = date
        newRecord.note = note
        newRecord.costParts = Double(costParts) ?? 0
        newRecord.costLabor = Double(costLabor) ?? 0
        newRecord.nextServiceKm = Int32((Int(mileage) ?? 0) + 10000)
        newRecord.nextServiceDate = Calendar.current.date(byAdding: .day, value: 180, to: date)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            do {
                try viewContext.save()
                isSaving = false
                dismiss()
            } catch {
                print("❌ Error saving: \(error.localizedDescription)")
                isSaving = false
            }
        }
    }
}

#Preview {
    AddServiceView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        .environmentObject(TabBarVisibility())
}
