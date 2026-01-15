import SwiftUI
import CoreData
import UIKit

struct ServiceHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("userEmail") private var currentUserEmail: String = ""

    // Все записи (один fetch), фильтруем по active car / owner локально
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    // Активная машина текущего пользователя
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(
            format: "isSelected == true AND ownerEmail == %@",
            (UserDefaults.standard.string(forKey: "userEmail") ?? "").lowercased()
        )
    ) private var selectedCar: FetchedResults<Car>

    @State private var showAddService = false
    @State private var editingRecord: ServiceRecord? = nil

    @State private var recordToDelete: ServiceRecord? = nil
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String = ""

    // ✅ Undo toast
    @State private var showUndoToast = false
    @State private var undoPayload: DeletedServicePayload? = nil
    @State private var undoHideWorkItem: DispatchWorkItem? = nil

    // ✅ Share (CSV/PDF)
    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }
    @State private var shareItem: ShareItem? = nil

    private var owner: String {
        currentUserEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var activeCar: Car? { selectedCar.first }

    private var recordsForActiveCar: [ServiceRecord] {
        guard let car = activeCar, !owner.isEmpty else { return [] }
        return allRecords.filter {
            $0.car == car && ($0.user?.email ?? "").lowercased() == owner
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, Color(hex: "#1A1A40")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                header

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if activeCar == nil {
                    emptyState(
                        title: "No active car",
                        subtitle: "Select a car first to see service history."
                    )
                } else if recordsForActiveCar.isEmpty {
                    emptyState(
                        title: "No service records yet",
                        subtitle: "Add your first service to start building history."
                    )
                } else {
                    List {
                        ForEach(recordsForActiveCar, id: \.objectID) { rec in
                            serviceRow(rec)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)

                                // ✅ Swipe — обе кнопки справа
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button {
                                        editingRecord = rec
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    .tint(Color(hex: "#FFD54F"))

                                    Button(role: .destructive) {
                                        recordToDelete = rec
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }

                                // ✅ Long-press menu (Edit/Delete)
                                .contextMenu {
                                    Button {
                                        editingRecord = rec
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }

                                    Button(role: .destructive) {
                                        recordToDelete = rec
                                        showDeleteConfirm = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.top, 10)

            // ✅ Undo Toast overlay
            if showUndoToast, let undoPayload {
                undoToast(payload: undoPayload)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(100)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        showAddService = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "#FFD54F"))
                    }

                    Menu {
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export CSV", systemImage: "doc.text")
                        }

                        Button {
                            exportPDF_A4()
                        } label: {
                            Label("Export PDF (A4)", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(Color(hex: "#FFD54F"))
                    }
                }
            }
        }
        .sheet(isPresented: $showAddService) {
            AddServiceView(
                prefilledType: nil,
                prefilledMileage: activeCar?.mileage ?? 0,
                prefilledDate: Date()
            )
            .environment(\.managedObjectContext, viewContext)
            .environmentObject(TabBarVisibility())
        }
        .sheet(item: $editingRecord) { rec in
            EditServiceView(record: rec)
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }
        .confirmationDialog(
            "Delete this service record?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let rec = recordToDelete { deleteServiceWithUndo(rec) }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    // MARK: - UI

    private var header: some View {
        VStack(spacing: 6) {
            Text("Service History")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: .cyan.opacity(0.6), radius: 10)

            if let car = activeCar {
                Text("\(car.name ?? "Car") • \(car.year ?? "—") • \(Int(car.mileage)) km")
                    .foregroundColor(.white.opacity(0.65))
                    .font(.subheadline)
            }
        }
        .padding(.top, 10)
        .padding(.horizontal, 16)
    }

    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(spacing: 10) {
            Spacer().frame(height: 40)

            Text(title)
                .foregroundColor(.white)
                .font(.title3.weight(.bold))

            Text(subtitle)
                .foregroundColor(.white.opacity(0.65))
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            NeonButton(title: "Add Service Record") {
                showAddService = true
            }
            .padding(.top, 10)
            .padding(.horizontal, 60)

            Spacer()
        }
    }

    private func serviceRow(_ rec: ServiceRecord) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(rec.type ?? "Service")
                    .foregroundColor(.white)
                    .font(.headline)

                Spacer()

                Text("$\(rec.totalCost, specifier: "%.2f")")
                    .foregroundColor(Color(hex: "#FFD54F"))
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 10) {
                Text("\(Int(rec.mileage)) km")
                    .foregroundColor(.white.opacity(0.8))
                    .font(.subheadline)

                Text("•")
                    .foregroundColor(.white.opacity(0.35))

                Text(formatDate(rec.date))
                    .foregroundColor(.white.opacity(0.7))
                    .font(.subheadline)

                Spacer()

                if rec.nextServiceKm > 0, let nd = rec.nextServiceDate {
                    Text("\(Int(rec.nextServiceKm)) km • \(formatDate(nd))")
                        .foregroundColor(.cyan.opacity(0.9))
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
            }

            if let note = rec.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(note)
                    .foregroundColor(.white.opacity(0.55))
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.white.opacity(0.07))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.cyan.opacity(0.20), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Export

    private func exportCSV() {
        errorMessage = ""
        guard let car = activeCar else { errorMessage = "No active car selected."; return }
        let records = recordsForActiveCar
        guard !records.isEmpty else { errorMessage = "No records to export."; return }

        let safeName = (car.name ?? "Car").replacingOccurrences(of: " ", with: "_")
        let fileName = "FluiDex_ServiceHistory_\(safeName).csv"

        let csv = ServiceExportManager.shared.makeCSV(car: car, records: records)
        do {
            let url = try ServiceExportManager.shared.writeCSVToTempFile(fileName: fileName, csv: csv)
            shareItem = ShareItem(url: url)
        } catch {
            errorMessage = "CSV export failed: \(error.localizedDescription)"
        }
    }

    private func exportPDF_A4() {
        errorMessage = ""
        guard let car = activeCar else { errorMessage = "No active car selected."; return }
        let records = recordsForActiveCar
        guard !records.isEmpty else { errorMessage = "No records to export."; return }

        let safeName = (car.name ?? "Car").replacingOccurrences(of: " ", with: "_")
        let fileName = "FluiDex_ServiceHistory_\(safeName)_A4.pdf"

        let data = ServiceExportManager.shared.makePDFDataA4(car: car, records: records)
        do {
            let url = try ServiceExportManager.shared.writePDFToTempFile(fileName: fileName, data: data)
            shareItem = ShareItem(url: url)
        } catch {
            errorMessage = "PDF export failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Undo Toast

    private func undoToast(payload: DeletedServicePayload) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "trash.slash.fill")
                    .foregroundColor(.white.opacity(0.9))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Deleted: \(payload.type)")
                        .foregroundColor(.white)
                        .font(.subheadline.weight(.semibold))
                    Text("You can undo this action.")
                        .foregroundColor(.white.opacity(0.75))
                        .font(.caption)
                }

                Spacer()

                Button {
                    undoDelete()
                } label: {
                    Text("Undo")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.black)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(Color.white.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
            )
            .cornerRadius(16)
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
        }
    }

    private func showUndoToastFor(_ payload: DeletedServicePayload) {
        undoHideWorkItem?.cancel()
        undoPayload = payload

        withAnimation(.easeInOut(duration: 0.2)) {
            showUndoToast = true
        }

        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.2)) {
                showUndoToast = false
            }
            undoPayload = nil
        }
        undoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: work)
    }

    private func undoDelete() {
        guard let payload = undoPayload else { return }

        undoHideWorkItem?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) { showUndoToast = false }

        let restored = ServiceRecord(context: viewContext)
        restored.id = payload.id
        restored.type = payload.type
        restored.mileage = payload.mileage
        restored.date = payload.date
        restored.note = payload.note
        restored.costParts = payload.costParts
        restored.costLabor = payload.costLabor
        restored.totalCost = payload.totalCost
        restored.nextServiceKm = payload.nextServiceKm
        restored.nextServiceDate = payload.nextServiceDate

        if let car = try? viewContext.existingObject(with: payload.carObjectID) as? Car {
            restored.car = car
        }
        if let userID = payload.userObjectID,
           let user = try? viewContext.existingObject(with: userID) as? User {
            restored.user = user
        }

        do {
            try viewContext.save()

            if let car = restored.car {
                recomputeMaintenance(for: car, serviceType: restored.type ?? "Other")
            }

            undoPayload = nil
        } catch {
            errorMessage = "Undo failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Delete + Maintenance auto-update + Undo snapshot

    private func deleteServiceWithUndo(_ rec: ServiceRecord) {
        errorMessage = ""

        guard let car = rec.car else {
            errorMessage = "Cannot delete: no car attached."
            return
        }

        let payload = DeletedServicePayload(from: rec)
        let type = rec.type ?? "Other"

        viewContext.delete(rec)

        do {
            try viewContext.save()

            recomputeMaintenance(for: car, serviceType: type)
            showUndoToastFor(payload)

        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Maintenance recompute

    private func normalizeServiceKey(_ type: String) -> String {
        let t = type.lowercased()
        if t.contains("oil") { return "oil" }
        if t.contains("brake") { return "brake" }
        if t.contains("battery") { return "battery" }
        if t.contains("fluid") { return "fluid" }
        if t.contains("tire") { return "tire" }
        if t.contains("inspect") { return "inspect" }
        return "other"
    }

    private func maintenanceMatches(serviceKey: String, item: MaintenanceItem) -> Bool {
        let title = (item.title ?? "").lowercased()
        let cat = (item.category ?? "").lowercased()

        switch serviceKey {
        case "oil": return title.contains("oil") || cat.contains("oil")
        case "brake": return title.contains("brake") || cat.contains("brake")
        case "battery": return title.contains("battery") || cat.contains("battery")
        case "fluid": return title.contains("fluid") || cat.contains("fluid")
        case "tire": return title.contains("tire") || cat.contains("tire")
        case "inspect":
            return title.contains("inspect") || title.contains("filter")
                || cat.contains("inspect") || cat.contains("filter")
        default:
            return false
        }
    }

    private func recomputeMaintenance(for car: Car, serviceType: String) {
        let key = normalizeServiceKey(serviceType)
        guard key != "other" else { return }

        let miReq: NSFetchRequest<MaintenanceItem> = MaintenanceItem.fetchRequest()
        miReq.predicate = NSPredicate(format: "car == %@", car)
        let items = (try? viewContext.fetch(miReq)) ?? []
        let matchedItems = items.filter { maintenanceMatches(serviceKey: key, item: $0) }
        guard !matchedItems.isEmpty else { return }

        let srReq: NSFetchRequest<ServiceRecord> = ServiceRecord.fetchRequest()
        srReq.predicate = NSPredicate(format: "car == %@", car)
        srReq.sortDescriptors = [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)]
        let records = (try? viewContext.fetch(srReq)) ?? []

        let latestSameType = records.first(where: { normalizeServiceKey($0.type ?? "") == key })

        for item in matchedItems {
            if let last = latestSameType {
                item.lastChangeDate = last.date
                item.lastChangeMileage = last.mileage

                if item.intervalKm > 0 {
                    item.nextChangeMileage = last.mileage + item.intervalKm
                } else {
                    item.nextChangeMileage = 0
                }

                if item.intervalDays > 0, let d = last.date {
                    item.nextChangeDate = Calendar.current.date(byAdding: .day, value: Int(item.intervalDays), to: d)
                } else if let d = last.date {
                    item.nextChangeDate = Calendar.current.date(byAdding: .day, value: 180, to: d)
                }
            } else {
                item.lastChangeDate = nil
                item.lastChangeMileage = 0
            }
        }

        try? viewContext.save()
    }
}

// MARK: - Deleted payload for Undo

private struct DeletedServicePayload {
    let id: UUID?
    let type: String
    let mileage: Int32
    let date: Date?
    let note: String?

    let costParts: Double
    let costLabor: Double
    let totalCost: Double

    let nextServiceKm: Int32
    let nextServiceDate: Date?

    let carObjectID: NSManagedObjectID
    let userObjectID: NSManagedObjectID?

    init(from rec: ServiceRecord) {
        self.id = rec.id
        self.type = rec.type ?? "Service"
        self.mileage = rec.mileage
        self.date = rec.date
        self.note = rec.note

        self.costParts = rec.costParts
        self.costLabor = rec.costLabor
        self.totalCost = rec.totalCost

        self.nextServiceKm = rec.nextServiceKm
        self.nextServiceDate = rec.nextServiceDate

        self.carObjectID = rec.car?.objectID ?? rec.objectID
        self.userObjectID = rec.user?.objectID
    }
}

#Preview {
    NavigationStack {
        ServiceHistoryView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
