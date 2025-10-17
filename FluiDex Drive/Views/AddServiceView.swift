import SwiftUI
import CoreData

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @State private var serviceType = "Oil"
    @State private var mileage = ""
    @State private var date = Date()
    @State private var note = ""

    let serviceTypes = ["Oil", "Tires", "Fluids", "Other"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                Text("Add New Service")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                    .padding(.top, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Service Type")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    Picker("Select type", selection: $serviceType) {
                        ForEach(serviceTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mileage (km)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    TextField("Enter mileage", text: $mileage)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Note (optional)")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                    TextField("Enter note...", text: $note)
                        .padding()
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                Spacer()

                // 💛 Кнопка сохранения
                Button(action: saveService) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("Save Service")
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

    // 📦 Сохранение в CoreData
    private func saveService() {
        let newRecord = ServiceRecord(context: viewContext)
        newRecord.id = UUID()
        newRecord.type = serviceType
        newRecord.mileage = Int32(mileage) ?? 0
        newRecord.date = date
        newRecord.note = note

        do {
            try viewContext.save()
            print("✅ Saved: \(serviceType) — \(mileage) km")
            dismiss()
        } catch {
            print("❌ Error saving: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddServiceView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
