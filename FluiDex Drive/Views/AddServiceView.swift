import SwiftUI

struct AddServiceView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var serviceType = "Oil"
    @State private var mileage = ""
    @State private var date = Date()
    @State private var note = ""

    let serviceTypes = ["Oil", "Tires", "Fluids", "Other"]

    var body: some View {
        ZStack {
            // 🌌 Неоновый фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {
                // 🔹 Заголовок
                Text("Add New Service")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                    .padding(.top, 20)

                // 🔧 Тип обслуживания
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

                // ⛽ Пробег
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

                // 📅 Дата
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))

                    DatePicker("Select date", selection: $date, displayedComponents: .date)
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

                // 📝 Заметка
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
                Button(action: {
                    print("✅ Service saved: \(serviceType), \(mileage) km, \(note)")
                    dismiss()
                }) {
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
}

#Preview {
    AddServiceView()
}
