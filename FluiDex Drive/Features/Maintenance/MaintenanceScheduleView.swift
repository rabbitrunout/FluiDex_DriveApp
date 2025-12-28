import SwiftUI
import CoreData

struct MaintenanceScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // 👇 Фокусный элемент (приходит с Dashboard)
    private let focusItem: MaintenanceItem?

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

    // Для подсветки нужной строки
    @State private var highlightedID: NSManagedObjectID? = nil

    // ✅ Инициализатор с дефолтом (чтобы MaintenanceScheduleView() тоже работал)
    init(focusItem: MaintenanceItem? = nil) {
        self.focusItem = focusItem
    }

    // MARK: - Date formatter
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Удаление дублей (оставляем ближайшую дату по title)
    private func removeDuplicates(_ list: [MaintenanceItem]) -> [MaintenanceItem] {
        var unique: [String: MaintenanceItem] = [:]

        for item in list {
            guard let title = item.title else { continue }

            if let existing = unique[title] {
                if let d1 = item.nextChangeDate, let d2 = existing.nextChangeDate, d1 < d2 {
                    unique[title] = item
                }
            } else {
                unique[title] = item
            }
        }

        return Array(unique.values)
            .sorted { ($0.nextChangeDate ?? .distantFuture) < ($1.nextChangeDate ?? .distantFuture) }
    }

    // MARK: - Фильтрация под тип топлива + только выбранная машина
    private var filteredItems: [MaintenanceItem] {
        guard let car = selectedCar.first else { return Array(items) }

        // ✅ только задачи выбранной машины
        let carItems = items.filter { $0.car == car }

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let all = allowed.isEmpty
            ? Array(carItems)
            : carItems.filter { allowed.contains($0.title ?? "") }

        return removeDuplicates(all)
    }

    // MARK: - UI
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Maintenance Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .padding(.top, 40)

                if filteredItems.isEmpty {
                    Text("No maintenance tasks for this vehicle type.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(filteredItems) { item in
                                    scheduleRow(item)
                                        .id(item.objectID) // ✅ важно для scrollTo
                                }
                            }
                            .padding(.bottom, 30)
                        }
                        .onAppear {
                            focusIfNeeded(proxy)
                        }
                    }
                }

                Spacer()

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

    // MARK: - Focus logic
    private func focusIfNeeded(_ proxy: ScrollViewProxy) {
        guard let focusItem else { return }

        // Если focusItem отфильтровался (не относится к fuelType/машине), ничего не делаем
        let targetID = focusItem.objectID
        guard filteredItems.contains(where: { $0.objectID == targetID }) else { return }

        // Скроллим и подсвечиваем
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.45)) {
                proxy.scrollTo(targetID, anchor: .center)
            }
            highlightedID = targetID

            // Убираем подсветку через 2.5 сек
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    highlightedID = nil
                }
            }
        }
    }

    // MARK: - Row UI
    private func scheduleRow(_ item: MaintenanceItem) -> some View {
        let urgencyColor = colorForDate(item.nextChangeDate)
        let isHighlighted = (highlightedID == item.objectID)

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
        .background(
            ZStack {
                Color.white.opacity(0.05)

                // ✅ подсветка фокуса (неон)
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cyan.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.75), lineWidth: 1.5)
                        )
                        .shadow(color: .cyan.opacity(0.45), radius: 12)
                }
            }
        )
        .cornerRadius(16)
        .shadow(color: urgencyColor.opacity(0.35), radius: 6)
        .padding(.horizontal, 16)
    }

    private func colorForDate(_ date: Date?) -> Color {
        guard let date else { return .gray }
        let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0

        switch daysLeft {
        case ..<0:  return .red
        case 0...2: return .orange
        case 3...7: return .yellow
        default:    return .green
        }
    }
}

#Preview {
    MaintenanceScheduleView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
