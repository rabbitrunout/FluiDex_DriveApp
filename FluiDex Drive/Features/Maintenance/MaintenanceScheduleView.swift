import SwiftUI
import CoreData

struct MaintenanceScheduleView: View {
    @Environment(\.managedObjectContext) private var viewContext

    // 👇 Фокусный элемент (пришел с Dashboard / Alerts)
    private let focusItem: MaintenanceItem?

    init(focusItem: MaintenanceItem? = nil) {
        self.focusItem = focusItem
    }

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MaintenanceItem.nextChangeDate, ascending: true)],
        animation: .easeInOut
    ) private var items: FetchedResults<MaintenanceItem>

    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    ) private var selectedCar: FetchedResults<Car>

    @State private var showAddItem = false
    @State private var highlightedID: NSManagedObjectID? = nil

    // MARK: - Date formatter
    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Remove duplicates (keep nearest date by title)
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

    // MARK: - Fuel filtering
    private var filteredItems: [MaintenanceItem] {
        guard let car = selectedCar.first else { return Array(items) }

        let allowed = MaintenanceRules.allowedTasks(for: car.fuelType ?? "")
        let all = allowed.isEmpty ? Array(items) : items.filter { allowed.contains($0.title ?? "") }
        let cleaned = removeDuplicates(all)

        return cleaned.sorted {
            ($0.nextChangeDate ?? .distantFuture) < ($1.nextChangeDate ?? .distantFuture)
        }
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

            VStack(spacing: 16) {
                Text("Maintenance Schedule")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 12)
                    .padding(.top, 22)

                if filteredItems.isEmpty {
                    Text("No maintenance tasks for this vehicle type.")
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 40)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 14) {
                                ForEach(filteredItems) { item in
                                    scheduleRow(item)
                                        .id(item.objectID) // 👈 ключ для scrollTo
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .onAppear {
                            // 👇 авто-фокус при открытии
                            guard let focusItem else { return }
                            let id = focusItem.objectID

                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                                    proxy.scrollTo(id, anchor: .center)
                                }
                                highlightedID = id

                                // подсветка исчезает мягко
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    withAnimation(.easeOut(duration: 0.6)) {
                                        highlightedID = nil
                                    }
                                }
                            }
                        }
                    }
                }

                NeonButton(title: "Add Maintenance Task") {
                    showAddItem = true
                }
                .sheet(isPresented: $showAddItem) {
                    AddMaintenanceItemView()
                        .environment(\.managedObjectContext, viewContext)
                }
                .padding(.bottom, 18)
            }
            .padding(.horizontal, 8)
        }
        .navigationBarBackButtonHidden(false)
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

                // 👇 подсветка фокуса
                if isHighlighted {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "#FFD54F").opacity(0.95), lineWidth: 2)
                        .shadow(color: Color(hex: "#FFD54F").opacity(0.35), radius: 10)
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
    MaintenanceScheduleView(focusItem: nil)
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
