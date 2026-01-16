import SwiftUI
import CoreData

struct RepairOrphanRecordsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @AppStorage("userEmail") private var currentUserEmail: String = ""

    let activeCarObjectID: NSManagedObjectID?
    let orphanObjectIDs: [NSManagedObjectID]

    @State private var selectedCarID: NSManagedObjectID? = nil
    @State private var selectedOrphans = Set<String>() // uri strings
    @State private var errorMessage: String = ""
    @State private var isSaving = false

    // ✅ Cars of this user (all, not only selected)
    @FetchRequest private var userCars: FetchedResults<Car>

    init(activeCarObjectID: NSManagedObjectID?, orphanObjectIDs: [NSManagedObjectID]) {
        self.activeCarObjectID = activeCarObjectID
        self.orphanObjectIDs = orphanObjectIDs

        let email = (UserDefaults.standard.string(forKey: "userEmail") ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        _userCars = FetchRequest<Car>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Car.name, ascending: true),
                NSSortDescriptor(keyPath: \Car.year, ascending: true)
            ],
            predicate: NSPredicate(format: "ownerEmail == %@", email),
            animation: .easeInOut
        )
    }

    private var orphanRecords: [ServiceRecord] {
        orphanObjectIDs.compactMap { id in
            (try? viewContext.existingObject(with: id)) as? ServiceRecord
        }
        .sorted { (a, b) in
            (a.date ?? .distantPast) > (b.date ?? .distantPast)
        }
    }

    private func uri(_ obj: NSManagedObject) -> String {
        obj.objectID.uriRepresentation().absoluteString
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.black, Color(hex: "#1A1A40")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 14) {
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // ✅ Choose car
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attach selected records to car:")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.footnote)

                        Menu {
                            ForEach(userCars, id: \.objectID) { car in
                                Button {
                                    selectedCarID = car.objectID
                                } label: {
                                    Text("\(car.name ?? "Car") • \(car.year ?? "—") • \(Int(car.mileage)) km")
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedCarTitle())
                                    .foregroundColor(.white)
                                    .font(.headline)

                                Spacer()

                                Image(systemName: "chevron.down")
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 16)

                    // ✅ List of orphan records with checkboxes
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            if orphanRecords.isEmpty {
                                Text("No unlinked records found.")
                                    .foregroundColor(.white.opacity(0.65))
                                    .padding(.top, 40)
                            } else {
                                ForEach(orphanRecords, id: \.objectID) { rec in
                                    orphanRow(rec)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 6)
                        .padding(.bottom, 20)
                    }

                    // ✅ Bottom buttons
                    HStack(spacing: 12) {
                        Button("Select All") {
                            selectedOrphans = Set(orphanRecords.map { uri($0) })
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.10))
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                        )

                        Button(isSaving ? "Saving..." : "Attach") {
                            attachSelected()
                        }
                        .disabled(isSaving)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(18)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }
            .navigationTitle("Repair History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(Color(hex: "#FFD54F"))
                }
            }
            .onAppear {
                // ✅ default target: active car (if exists), else first car
                if selectedCarID == nil {
                    selectedCarID = activeCarObjectID ?? userCars.first?.objectID
                }
                // ✅ preselect all (you can change if you want)
                selectedOrphans = Set(orphanRecords.map { uri($0) })
            }
        }
    }

    // MARK: - UI

    private func orphanRow(_ rec: ServiceRecord) -> some View {
        let key = uri(rec)
        let isOn = selectedOrphans.contains(key)

        return Button {
            if isOn { selectedOrphans.remove(key) }
            else { selectedOrphans.insert(key) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? Color(hex: "#FFD54F") : .white.opacity(0.35))
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(rec.type ?? "Service")
                            .foregroundColor(.white)
                            .font(.headline)

                        Spacer()

                        Text("$\(rec.totalCost, specifier: "%.2f")")
                            .foregroundColor(Color(hex: "#FFD54F"))
                            .font(.subheadline.weight(.semibold))
                    }

                    Text("\(Int(rec.mileage)) km • \(formatDate(rec.date))")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)

                    if let note = rec.note, !note.isEmpty {
                        Text(note)
                            .foregroundColor(.cyan.opacity(0.8))
                            .font(.caption)
                            .lineLimit(2)
                    }

                    Text("⚠️ Not linked to any car")
                        .foregroundColor(.yellow)
                        .font(.caption)
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
        .buttonStyle(.plain)
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }

    private func selectedCarTitle() -> String {
        guard let id = selectedCarID,
              let car = try? viewContext.existingObject(with: id) as? Car else {
            return "Choose car"
        }
        return "\(car.name ?? "Car") • \(car.year ?? "—") • \(Int(car.mileage)) km"
    }

    // MARK: - Attach

    private func attachSelected() {
        errorMessage = ""

        guard let carID = selectedCarID,
              let car = try? viewContext.existingObject(with: carID) as? Car else {
            errorMessage = "Choose a car first."
            return
        }

        let chosen = orphanRecords.filter { selectedOrphans.contains(uri($0)) }
        guard !chosen.isEmpty else {
            errorMessage = "Select at least one record."
            return
        }

        isSaving = true
        defer { isSaving = false }

        chosen.forEach { $0.car = car }

        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "Attach failed: \(error.localizedDescription)"
        }
    }
}
