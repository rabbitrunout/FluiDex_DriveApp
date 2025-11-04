import SwiftUI
import CoreData

struct MaintenanceScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // 🔍 Получаем все элементы обслуживания
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    ) private var items: FetchedResults<MaintenanceItem>

    @State private var showAddItem = false

    var body: some View {
        ZStack {
            // 🌌 Фон — в стиле FluiDex Drive
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 🏷 Заголовок
                Text("Maintenance Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .padding(.top, 40)

                // 📋 Список всех записей
                if items.isEmpty {
                    Text("No maintenance tasks yet.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 100)
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(items) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.title ?? "Unknown")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(item.category ?? "")
                                            .font(.caption)
                                            .foregroundColor(.cyan)
                                    }

                                    Text("Next change: \(formatDate(item.nextChangeDate))")
                                        .foregroundColor(Color(hex: "#FFD54F"))
                                        .font(.subheadline)

                                    if let lastDate = item.lastChangeDate {
                                        Text("Last change: \(formatDate(lastDate))")
                                            .foregroundColor(.white.opacity(0.6))
                                            .font(.caption)
                                    }

                                    Text("Interval: \(item.intervalDays) days")
                                        .foregroundColor(.white.opacity(0.7))
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.4), radius: 8)
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }

                Spacer()

                // ➕ Кнопка добавления
                NeonButton(title: "Add Maintenance Task") {
                    showAddItem = true
                }
                .sheet(isPresented: $showAddItem) {
                    AddMaintenanceItemView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(false)
    }

    // MARK: - Date Formatter
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

#Preview {
    MaintenanceScheduleView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
