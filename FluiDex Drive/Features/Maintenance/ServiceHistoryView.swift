import SwiftUI
import CoreData
import UIKit

struct ServiceHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var tabBar: TabBarVisibility
    @AppStorage("userEmail") private var currentUserEmail: String = ""

    @State private var selectedCategory: String = "All"
    @State private var showAddService = false

    // edit/delete states
    @State private var recordToEdit: ServiceRecord? = nil
    @State private var recordToDelete: ServiceRecord? = nil
    @State private var showDeleteAlert = false

    @State private var errorMessage: String = ""
    @State private var toast: String = ""

    // ✅ Share (CSV/PDF)
    private struct ShareItem: Identifiable {
        let id = UUID()
        let url: URL
    }
    @State private var shareItem: ShareItem? = nil

    // ✅ all records
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    // ✅ active car for current owner
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(
            format: "isSelected == true AND ownerEmail == %@",
            (UserDefaults.standard.string(forKey: "userEmail") ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
        )
    ) private var selectedCar: FetchedResults<Car>

    private var activeCar: Car? { selectedCar.first }

    // MARK: - Matching helpers

    private func norm(_ s: String?) -> String {
        (s ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func carSignature(owner: String, name: String, year: String) -> String {
        "\(norm(owner))|\(norm(name))|\(norm(year))"
    }

    private func signature(of car: Car?) -> String {
        carSignature(
            owner: car?.ownerEmail ?? "",
            name: car?.name ?? "",
            year: car?.year ?? "" // ✅ year is String
        )
    }

    // ✅ 1) match duplicate cars by signature (owner+name+year)
    private var recordsBySignature: [ServiceRecord] {
        guard let car = activeCar else { return [] }
        let sig = signature(of: car)
        return allRecords.filter { rec in
            guard let recCar = rec.car else { return false }
            return signature(of: recCar) == sig
        }
    }

    // ✅ 2) orphan records (car == nil)
    private var orphanRecords: [ServiceRecord] {
        allRecords.filter { $0.car == nil }
    }

    // ✅ union unique (signature + orphan)
    private var unionRecords: [ServiceRecord] {
        var seen = Set<String>()
        var out: [ServiceRecord] = []
        let combined = recordsBySignature + orphanRecords
        for r in combined {
            let key = r.objectID.uriRepresentation().absoluteString
            if !seen.contains(key) {
                seen.insert(key)
                out.append(r)
            }
        }
        return out
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
                            ForEach(filteredRecords()) { rec in
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
                HStack(spacing: 12) {
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

                    // ✅ Repair only if there are orphans
                    if activeCar != nil && orphanRecords.count > 0 {
                        Button {
                            repairHistoryToActiveCar()
                        } label: {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Repair")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 120)
                            .padding()
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(22)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                            )
                        }
                    }
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
        .onAppear { withAnimation { tabBar.isVisible = false } }
        .onDisappear { withAnimation { tabBar.isVisible = true } }

        // ✅ Toolbar export menu (CSV/PDF) — как в старой версии
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
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

        // ✅ Add sheet
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

        // ✅ Edit sheet
        .sheet(item: $recordToEdit) { rec in
            EditServiceView(record: rec)
                .presentationDetents([.medium, .large])
                .presentationCornerRadius(25)
                .environment(\.managedObjectContext, viewContext)
        }

        // ✅ Share sheet for CSV/PDF
        .sheet(item: $shareItem) { item in
            ShareSheet(items: [item.url])
        }

        // ✅ Delete alert
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
        let base = unionRecords
        return selectedCategory == "All" ? base : base.filter { $0.type == selectedCategory }
    }

    private func formattedDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    // MARK: - Export

    private func exportCSV() {
        errorMessage = ""
        guard let car = activeCar else { errorMessage = "No active car selected."; return }
        let records = filteredRecords() // ✅ respects category filter
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
        let records = filteredRecords() // ✅ respects category filter
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

    // MARK: - Repair

    private func repairHistoryToActiveCar() {
        errorMessage = ""
        guard let targetCar = activeCar else { return }

        let toFix = orphanRecords
        guard !toFix.isEmpty else { return }

        toFix.forEach { $0.car = targetCar }

        do {
            try viewContext.save()
            toast = "✅ Repaired \(toFix.count) record(s)."
        } catch {
            errorMessage = "Repair failed: \(error.localizedDescription)"
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
