import SwiftUI
import CoreData

struct MaintenanceScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // Все элементы обслуживания
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    ) private var items: FetchedResults<MaintenanceItem>

    // Выбранная машина (fuelType)
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    ) private var selectedCar: FetchedResults<Car>

    @State private var showAddItem = false

    // MARK: - Date formatter
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Удаление дублей
    private func removeDuplicates(_ list: [MaintenanceItem]) -> [MaintenanceItem] {
        var unique: [String: MaintenanceItem] = [:]

        for item in list {
            guard let title = item.title else { continue }

            if let existing = unique[title] {
                if let d1 = item.nextChangeDate, let d2 = existing.nextChangeDate {
                    if d1 < d2 {
                        unique[title] = item
                    }
                }
            } else {
                unique[title] = item
            }
        }

        return Array(unique.values)
            .sorted { ($0.nextChangeDate ?? .distantFuture) < ($1.nextChangeDate ?? .distantFuture) }
    }

    // MARK: - Фильтрация под тип топлива
    private var filteredItems: [MaintenanceItem] {
        guard let car = selectedCar.first else { return Array(items) }

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let all = allowed.isEmpty ? Array(items) : items.filter { allowed.contains($0.title ?? "") }

        // удаляем дубликаты
        let cleaned = removeDuplicates(all)

        // сортировка по срочности
        return cleaned.sorted { a, b in
            let da = a.nextChangeDate ?? Date.distantFuture
            let db = b.nextChangeDate ?? Date.distantFuture
            return da < db
        }
    }


    // MARK: - UI
    var body: some View {
        ZStack {
            // фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // Заголовок
                Text("Maintenance Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .padding(.top, 40)

                // Если пусто
                if filteredItems.isEmpty {
                    Text("No maintenance tasks for this vehicle type.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)

                } else {
                    // Список
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(filteredItems) { item in
                                scheduleRow(item)
                            }
                        }
                        .padding(.bottom, 30)
                    }
                }

                Spacer()

                // Кнопка добавления
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

    // MARK: - Row UI
    private func scheduleRow(_ item: MaintenanceItem) -> some View {

        let urgencyColor = colorForDate(item.nextChangeDate)

        return HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(urgencyColor)
                        .frame(width: 10, height: 10)

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
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .shadow(color: urgencyColor.opacity(0.4), radius: 6)
        .padding(.horizontal, 16)
    }

    
    private func colorForDate(_ date: Date?) -> Color {
        guard let date else { return .gray }

        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0

        switch daysLeft {
        case ..<0:  return .red        // просрочено
        case 0...2: return .orange     // срочно
        case 3...7: return .yellow     // скоро
        default:    return .green      // все ок
        }
    }

}

#Preview {
    MaintenanceScheduleView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
