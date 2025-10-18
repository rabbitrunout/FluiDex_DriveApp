import SwiftUI
import CoreData

struct ServiceLogView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var selectedCategory: String = "All"
    @State private var showAddService = false
    @State private var showDeleteAlert = false
    @State private var recordToDelete: ServiceRecord? = nil
    @State private var deletingServiceID: String? = nil
    @State private var animateCar = false
    @State private var showDust = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var serviceRecords: FetchedResults<ServiceRecord>

    let categories = ["All", "Oil", "Tires", "Fluids", "Battery", "Brakes", "Inspection", "Other"]

    var body: some View {
        ZStack {
            // 🌌 Неоновый фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            

            VStack(spacing: 20) {
                
                // 🏁 Заголовок
                Text("Service Log")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                    .padding(.top, 30)

                // 🟡 Категории
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedCategory = category
                                }
                            } label: {
                                Text(category)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedCategory == category ? .black : .white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        selectedCategory == category
                                        ? Color(hex: "#FFD54F")
                                        : Color.white.opacity(0.08)
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: selectedCategory == category ? Color.yellow.opacity(0.4) : .clear, radius: 8, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // 🔧 Список сервисов
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if filteredRecords().isEmpty {
                            Text("No service records yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 50)
                        } else {
                            ForEach(filteredRecords()) { record in
                                ZStack(alignment: .leading) {
                                    // 🧾 Карточка сервиса
                                    HStack(spacing: 16) {
                                        let iconName = iconForType(record.type ?? "")
                                        Image(systemName: iconName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 36, height: 36)
                                            .foregroundColor(colorForType(record.type ?? ""))
                                            .shadow(color: colorForType(record.type ?? "").opacity(0.7), radius: 12, y: 5)
//                                            .glow(color: colorForType(record.type ?? ""), radius: 15)
                                            .animation(.easeInOut(duration: 0.3), value: record.type)

                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(record.type ?? "Unknown")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)

                                            Text("\(record.mileage) km • \(formattedDate(record.date))")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.7))

                                            if let note = record.note, !note.isEmpty {
                                                Text(note)
                                                    .font(.system(size: 13))
                                                    .foregroundColor(.cyan.opacity(0.8))
                                            }
                                        }

                                        Spacer()

                                        Button {
                                            withAnimation(.spring()) {
                                                recordToDelete = record
                                                showDeleteAlert = true
                                            }
                                        } label: {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 16))
                                                .padding(6)
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(16)
                                    .shadow(color: .cyan.opacity(0.3), radius: 10, y: 4)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.cyan.opacity(0.3), lineWidth: 0.8)
                                    )
                                    .padding(.horizontal, 20)
                                    .zIndex(0)

                                    // 🚗 Машинка + пыль при удалении
                                    if deletingServiceID == record.objectID.uriRepresentation().absoluteString {
                                        ZStack {
                                            if showDust {
                                                ForEach(0..<6) { i in
                                                    Circle()
                                                        .fill(Color.yellow.opacity(Double.random(in: 0.2...0.7)))
                                                        .frame(width: CGFloat.random(in: 8...16))
                                                        .offset(
                                                            x: CGFloat.random(in: -20...30),
                                                            y: CGFloat.random(in: -20...30)
                                                        )
                                                        .blur(radius: 4)
                                                        .transition(.opacity)
                                                        .animation(
                                                            .easeOut(duration: 0.8)
                                                                .delay(Double(i) * 0.05),
                                                            value: showDust
                                                        )
                                                }
                                            }

                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.yellow.opacity(0.7), .clear]),
                                                startPoint: .trailing,
                                                endPoint: .leading
                                            )
                                            .frame(width: 140, height: 8)
                                            .blur(radius: 6)
                                            .offset(x: animateCar ? 400 : -100, y: 20)
                                            .opacity(animateCar ? 0.4 : 0)
                                            .animation(.easeOut(duration: 1.2), value: animateCar)

                                            Image(systemName: "car.fill")
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 80, height: 40)
                                                .foregroundColor(.yellow)
                                                .shadow(color: .yellow.opacity(0.9), radius: 12, y: 4)
                                                .offset(x: animateCar ? 420 : -120)
                                                .rotationEffect(.degrees(animateCar ? 6 : -10))
                                                .animation(.easeInOut(duration: 1.2), value: animateCar)
                                        }
                                        .zIndex(2)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding(.bottom, 80)
                }

                Spacer()

                // ➕ Add Service
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showAddService = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("Add Service")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FFD54F"))
                    .cornerRadius(30)
                    .shadow(color: Color.yellow.opacity(0.4), radius: 10, y: 6)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
                .sheet(isPresented: $showAddService) {
                    AddServiceView()
                        .presentationDetents([.medium, .large])
                        .presentationCornerRadius(25)
                }
            }

            // 🌟 Модалка удаления
            if showDeleteAlert {
                deleteAlertOverlay()
            }
        }
    }

    // MARK: - 🧱 Helpers

    private func formattedDate(_ date: Date?) -> String {
        guard let date = date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func colorForType(_ type: String) -> Color {
        switch type {
        case "Oil": return Color(hex: "#FFD54F")
        case "Tires": return Color(hex: "#FF7043")
        case "Fluids": return Color(hex: "#4FC3F7")
        case "Battery": return Color(hex: "#00E676")
        case "Brakes": return Color(hex: "#EF5350")
        case "Inspection": return Color(hex: "#BA68C8")
        case "Other": return Color(hex: "#B0BEC5")
        default: return Color.cyan
        }
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "Oil": return "drop.triangle.fill"
        case "Tires": return "car.circle.fill"
        case "Fluids": return "thermometer.low"
        case "Battery": return "bolt.car.fill"
        case "Brakes": return "stop.circle.fill"
        case "Inspection": return "magnifyingglass.circle.fill"
        case "Other": return "gearshape.fill"
        default: return "wrench.and.screwdriver.fill"
        }
    }

    private func filteredRecords() -> [ServiceRecord] {
        selectedCategory == "All" ? Array(serviceRecords)
                                  : serviceRecords.filter { $0.type == selectedCategory }
    }

    private func deleteRecord(_ record: ServiceRecord) {
        withAnimation(.easeInOut(duration: 0.3)) {
            viewContext.delete(record)
            try? viewContext.save()
        }
    }

    // MARK: - 🗑 Alert
    private func deleteAlertOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture { withAnimation(.spring()) { showDeleteAlert = false } }

            VStack(spacing: 20) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.6), radius: 12)

                Text("Delete this record?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("This action cannot be undone.")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)

                HStack(spacing: 20) {
                    Button {
                        withAnimation(.spring()) { showDeleteAlert = false }
                    } label: {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(20)
                    }

                    Button {
                        if let record = recordToDelete {
                            deletingServiceID = record.objectID.uriRepresentation().absoluteString
                            showDust = true
                            animateCar = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                deleteRecord(record)
                                animateCar = false
                                showDust = false
                                deletingServiceID = nil
                            }
                        }
                        withAnimation(.spring()) { showDeleteAlert = false }
                    } label: {
                        Text("Delete")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(hex: "#FFD54F"))
                            .cornerRadius(20)
                            .shadow(color: .yellow.opacity(0.5), radius: 8, y: 4)
                    }
                }
            }
            .padding()
            .frame(maxWidth: 300)
            .background(Color.white.opacity(0.1))
            .cornerRadius(25)
            .shadow(color: .cyan.opacity(0.4), radius: 12)
            .transition(.scale.combined(with: .opacity))
        }
        .zIndex(3)
    }
}

// MARK: - 🌈 Glow Extension
//extension View {
//    func glow(color: Color = .cyan, radius: CGFloat = 20) -> some View {
//        self
//            .shadow(color: color.opacity(0.6), radius: radius / 2)
//            .shadow(color: color.opacity(0.4), radius: radius)
//            .shadow(color: color.opacity(0.2), radius: radius * 2)
//    }
//}

#Preview("ServiceLogView Preview") {
    let context = PersistenceController.shared.container.viewContext
    ServiceLogView()
        .environment(\.managedObjectContext, context)
        .environmentObject(TabBarVisibility())
        .background(Color.black)
}

