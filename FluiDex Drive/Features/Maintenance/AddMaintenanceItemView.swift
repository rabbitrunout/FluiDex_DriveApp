import SwiftUI
import CoreData

struct AddMaintenanceItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var intervalDays: String = ""
    @State private var nextChangeDate = Date()
    @State private var showSuccess = false

    // 🔔 Предпросмотр уведомлений
    private var scheduledDates: [Date] {
        let offsets = [7, 3, 0]
        return offsets.compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: nextChangeDate)
        }.filter { $0 > Date() }
    }

    var body: some View {
        ZStack {
            // 🌌 Фон FluiDex Drive
            LinearGradient(
                colors: [.black, Color(hex: "#1A1A40")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                // 🏷 Заголовок
                Text("Add Maintenance Item")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .glow(color: .cyan, radius: 12)
                    .padding(.top, 10)

                // ✏️ Поля ввода
                glowingField("Title", text: $title, icon: "wrench.and.screwdriver")
                glowingField("Category", text: $category, icon: "list.bullet")
                glowingField("Interval (days)", text: $intervalDays, icon: "calendar.badge.clock")

                // 📅 Дата следующего обслуживания
                VStack(alignment: .leading, spacing: 6) {
                    DatePicker("Next Change Date", selection: $nextChangeDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                        )
                        .padding(.horizontal, 8)

                    // 🔔 Предпросмотр уведомлений
                    if !scheduledDates.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications will be sent:")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))

                            ForEach(scheduledDates, id: \.self) { date in
                                Text("• \(formatDate(date))")
                                    .font(.system(size: 15))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 4)
                        .transition(.opacity.combined(with: .scale))
                    }
                }

                Spacer(minLength: 20)

                // 💾 Кнопка сохранения
                NeonButton(title: "Save Maintenance") {
                    saveItem()
                }

                // ✨ Успешное сохранение
                if showSuccess {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                            .shadow(color: .green.opacity(0.7), radius: 10)
                        Text("Reminder Set!")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(.top, 4)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 40)
        }
    }

    // MARK: - 💾 Сохранение и уведомления
    private func saveItem() {
        guard !title.isEmpty, !category.isEmpty else { return }

        let newItem = MaintenanceItem(context: viewContext)
        newItem.id = UUID()
        newItem.title = title
        newItem.category = category
        newItem.intervalDays = Int32(intervalDays) ?? 0
        newItem.lastChangeDate = Date()
        newItem.nextChangeDate = nextChangeDate

        do {
            try viewContext.save()

            // 🔔 Создаём уведомления
            NotificationManager.shared.scheduleNotifications(for: newItem)

            withAnimation(.spring()) {
                showSuccess = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            print("❌ Failed to save item: \(error.localizedDescription)")
        }
    }

    // MARK: - 📅 Форматирование даты
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    AddMaintenanceItemView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
