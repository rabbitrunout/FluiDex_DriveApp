import SwiftUI
import CoreData
import UIKit

struct ServiceHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility
    @AppStorage("userEmail") private var currentUserEmail: String = ""

    @State private var selectedCategory: String = "All"
    @State private var showAddService = false

    @State private var recordToEdit: ServiceRecord? = nil
    @State private var recordToDelete: ServiceRecord? = nil
    @State private var showDeleteAlert = false

    @State private var errorMessage: String = ""
    @State private var toast: String = ""

    // ✅ заставляем SwiftUI обновляться при смене active car
    @State private var refreshToken = UUID()

    // ✅ all records
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    // ✅ ВСЕ машины пользователя (не только selected)
    @FetchRequest private var userCars: FetchedResults<Car>

    init() {
        let email = (UserDefaults.standard.string(forKey: "userEmail") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        _userCars = FetchRequest<Car>(
            sortDescriptors: [NSSortDescriptor(keyPath: \Car.name, ascending: true)],
            predicate: NSPredicate(format: "ownerEmail == %@", email),
            animation: .easeInOut
        )
    }

    private var activeCar: Car? {
        userCars.first(where: { $0.isSelected })
    }

    // ✅ только записи этой машины (строго по objectID)
    private var recordsForActiveCar: [ServiceRecord] {
        guard let car = activeCar else { return [] }
        let carID = car.objectID
        return allRecords.filter { $0.car?.objectID == carID }
    }

    let categories = ["All", "Oil", "Tires", "Fluids", "Battery", "Brakes", "Inspection", "Other"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {

                Text("Service History")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                    .padding(.top, 24)

                if let car = activeCar {
                    Text("\(car.name ?? "") • \(car.year ?? "") • \(Int(car.mileage)) km")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.65))
                } else {
                    Text("No active car selected")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.65))
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // categories
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedCategory = cat
                                }
                            } label: {
                                Text(cat)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedCategory == cat ? .black : .white)
                                    .padding(.vertical, 9)
                                    .padding(.horizontal, 16)
                                    .background(selectedCategory == cat ? Color(hex: "#FFD54F") : Color.white.opacity(0.08))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                }

                // list
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        if activeCar == nil {
                            Text("Select a car first.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 50)
                        } else if filteredRecords().isEmpty {
                            Text("No service records yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 50)
                        } else {
                            ForEach(filteredRecords(), id: \.objectID) { rec in
                                recordCard(rec)
                                    .contentShape(Rectangle())
                                    .onTapGesture { recordToEdit = rec }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {

                                        Button(role: .destructive) {
                                            recordToDelete = rec
                                            showDeleteAlert = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }

                                        Button {
                                            recordToEdit = rec
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        .tint(Color(hex: "#FFD54F"))
                                    }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 90)
                }

                // buttons row
                Button {
                    showAddService = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Service")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FFD54F"))
                    .cornerRadius(22)
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 14)

                if !toast.isEmpty {
                    Text(toast)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 6)
                }
            }
        }
        .id(refreshToken) // ✅ форсим перерисовку при смене машины

        .onAppear { withAnimation { tabBar.isVisible = false } }
        .onDisappear { withAnimation { tabBar.isVisible = true } }

        // ✅ слушаем смену активной машины
        .onReceive(NotificationCenter.default.publisher(for: .activeCarChanged)) { _ in
            viewContext.refreshAllObjects()
            refreshToken = UUID()
        }

        // Add sheet
        .sheet(isPresented: $showAddService) {
            AddServiceView(
                prefilledType: nil,
                prefilledMileage: activeCar?.mileage ?? 0,
                prefilledDate: Date(),
                maintenanceItemID: nil,
                carObjectID: activeCar?.objectID
            )
            .presentationDetents([.medium, .large])
            .presentationCornerRadius(25)
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(TabBarVisibility())
        }

        // Edit sheet
        .sheet(item: $recordToEdit) { rec in
            EditServiceView(record: rec)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(25)
                .environment(\.managedObjectContext, viewContext)
        }

        // Delete confirm
        .alert("Delete this service?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { recordToDelete = nil }
            Button("Delete", role: .destructive) {
                if let rec = recordToDelete { deleteRecord(rec) }
                recordToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - UI

    private func recordCard(_ rec: ServiceRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rec.type ?? "Unknown")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text("$\(rec.totalCost, specifier: "%.2f")")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "#FFD54F"))
            }

            Text("\(Int(rec.mileage)) km • \(formattedDate(rec.date))")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.65))

            if let note = rec.note, !note.isEmpty {
                Text(note)
                    .font(.system(size: 13))
                    .foregroundColor(.cyan.opacity(0.8))
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Filtering

    private func filteredRecords() -> [ServiceRecord] {
        let base = recordsForActiveCar
        return selectedCategory == "All" ? base : base.filter { $0.type == selectedCategory }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Delete

    private func deleteRecord(_ rec: ServiceRecord) {
        errorMessage = ""
        viewContext.delete(rec)
        do {
            try viewContext.save()
            toast = "🗑 Deleted."
        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        ServiceHistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            .environmentObject(TabBarVisibility())
    }
}
