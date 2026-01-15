import SwiftUI
import CoreData

struct AddMaintenanceItemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("userEmail") private var userEmail: String = ""

    // UI inputs
    @State private var title: String = ""
    @State private var category: String = ""

    @State private var intervalDaysText: String = ""
    @State private var intervalKmText: String = ""

    @State private var lastServiceDate: Date = Date()
    @State private var lastServiceMileageText: String = ""

    @State private var showSuccess = false
    @State private var errorText: String = ""

    // ✅ active car for current user
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true AND ownerEmail == %@", (UserDefaults.standard.string(forKey: "userEmail") ?? "").lowercased())
    ) private var selectedCar: FetchedResults<Car>

    private var activeCar: Car? { selectedCar.first }

    // 🔔 Preview notification dates (based on computed nextChangeDate)
    private var scheduledDates: [Date] {
        let nextDate = computedNextChangeDate
        let offsets = [7, 3, 0]
        return offsets.compactMap {
            Calendar.current.date(byAdding: .day, value: -$0, to: nextDate)
        }.filter { $0 > Date() }
    }

    // MARK: - Computed values

    private var intervalDays: Int32 {
        Int32(Int(intervalDaysText) ?? 0)
    }

    private var intervalKm: Int32 {
        Int32(Int(intervalKmText) ?? 0)
    }

    private var lastServiceMileage: Int32 {
        Int32(Int(lastServiceMileageText) ?? 0)
    }

    private var computedNextChangeDate: Date {
        if intervalDays > 0 {
            return Calendar.current.date(byAdding: .day, value: Int(intervalDays), to: lastServiceDate) ?? lastServiceDate
        } else {
            // if user didn't set intervalDays -> default 180d
            return Calendar.current.date(byAdding: .day, value: 180, to: lastServiceDate) ?? lastServiceDate
        }
    }

    private var computedNextChangeMileage: Int32 {
        if intervalKm > 0 && lastServiceMileage > 0 {
            return lastServiceMileage + intervalKm
        }
        return 0
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    Text("Add Maintenance Task")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .glow(color: .cyan, radius: 12)
                        .padding(.top, 10)

                    if activeCar == nil {
                        Text("No active car selected. Please select a car first.")
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    if !errorText.isEmpty {
                        Text(errorText)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    glowingField("Title (e.g. Engine Oil)", text: $title, icon: "wrench.and.screwdriver")
                    glowingField("Category (e.g. Fluids)", text: $category, icon: "list.bullet")

                    // ✅ intervals
                    glowingField("Interval (days)", text: $intervalDaysText, icon: "calendar.badge.clock")
                        .keyboardType(.numberPad)

                    glowingField("Interval (km)", text: $intervalKmText, icon: "gauge.with.dots.needle.bottom.50percent")
                        .keyboardType(.numberPad)

                    // ✅ last service inputs (THIS IS THE FIX)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Service Date")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.9))

                        DatePicker("", selection: $lastServiceDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .colorScheme(.dark)
                            .tint(Color(hex: "#FFD54F"))
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.6), lineWidth: 1.2)
                            )
                    }

                    glowingField("Last Service Mileage (km)", text: $lastServiceMileageText, icon: "speedometer")
                        .keyboardType(.numberPad)

                    // ✅ live preview
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Next due (preview)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))

                        Text("Date: \(formatDate(computedNextChangeDate))")
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .font(.subheadline.weight(.semibold))

                        if computedNextChangeMileage > 0 {
                            Text("Mileage: \(formatKm(computedNextChangeMileage)) km")
                                .foregroundColor(.white.opacity(0.85))
                                .font(.subheadline)
                        } else {
                            Text("Mileage: — (set interval km + last mileage)")
                                .foregroundColor(.white.opacity(0.45))
                                .font(.caption)
                        }

                        // 🔔 notification preview
                        if !scheduledDates.isEmpty {
                            Text("Notifications:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.55))
                                .padding(.top, 4)

                            ForEach(scheduledDates, id: \.self) { d in
                                Text("• \(formatDate(d))")
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.cyan.opacity(0.35), lineWidth: 1)
                    )

                    Spacer(minLength: 10)

                    NeonButton(title: "Save Maintenance") {
                        saveItem()
                    }
                    .disabled(activeCar == nil)

                    if showSuccess {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.7), radius: 10)

                            Text("Saved!")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .transition(.scale.combined(with: .opacity))
                        .padding(.top, 6)
                    }

                    Spacer(minLength: 30)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Save
    private func saveItem() {
        errorText = ""

        guard let car = activeCar else {
            errorText = "Please select a car first."
            return
        }

        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let c = category.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !t.isEmpty, !c.isEmpty else {
            errorText = "Please fill Title and Category."
            return
        }

        let newItem = MaintenanceItem(context: viewContext)
        newItem.id = UUID()
        newItem.title = t
        newItem.category = c

        newItem.intervalDays = intervalDays
        newItem.intervalKm = intervalKm

        newItem.lastChangeDate = lastServiceDate
        newItem.lastChangeMileage = lastServiceMileage

        newItem.nextChangeDate = computedNextChangeDate
        newItem.nextChangeMileage = computedNextChangeMileage

        // ✅ relation to car
        newItem.car = car

        do {
            try viewContext.save()

            // 🔔 уведомления под nextChangeDate
            NotificationManager.shared.scheduleNotifications(for: newItem)

            withAnimation(.spring()) { showSuccess = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                dismiss()
            }
        } catch {
            errorText = "Failed to save: \(error.localizedDescription)"
        }
    }

    // MARK: - Formatting
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func formatKm(_ km: Int32) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        return nf.string(from: NSNumber(value: km)) ?? "\(km)"
    }
}



#Preview {
    AddMaintenanceItemView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
