import SwiftUI
import CoreData

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var isLoggedIn: Bool
    @AppStorage("currentUserName") private var currentUserName: String = "Guest"
    @AppStorage("currentUserEmail") private var currentUserEmail: String = "user@example.com"

    // 🧭 Активная машина
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true"),
        animation: .easeInOut
    ) private var selectedCar: FetchedResults<Car>

    // 🔧 Все сервисные записи
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ServiceRecord.date, ascending: false)],
        animation: .easeInOut
    ) private var allRecords: FetchedResults<ServiceRecord>

    @State private var showAddService = false
    @State private var showEditProfile = false

    var body: some View {
        ZStack {
            // 🌌 Фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    // 🧍 Профиль
                    HStack(spacing: 16) {
                        Circle()
                            .fill(Color.cyan.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 35))
                                    .foregroundColor(Color(hex: "#FFD54F"))
                            )
                            .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentUserName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            Text(currentUserEmail)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Spacer()

                        Button {
                            showEditProfile = true
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.7), radius: 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 30)

                    Divider()
                        .overlay(Color.cyan.opacity(0.4))
                        .padding(.horizontal, 60)

                    // 🚗 Активная машина
                    if let car = selectedCar.first {
                        VStack(spacing: 12) {
                            if let image = UIImage(named: car.imageName ?? "") {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 160)
                                    .cornerRadius(20)
                                    .shadow(color: .cyan.opacity(0.5), radius: 20, y: 8)
                            } else {
                                Image(systemName: "car.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 90)
                                    .foregroundColor(.yellow)
                                    .shadow(color: .cyan.opacity(0.8), radius: 10)
                            }

                            Text(car.name ?? "Unknown Car")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .cyan.opacity(0.8), radius: 10)

                            Text("\(car.year ?? "Year Unknown") • \(car.mileage) km")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.subheadline)
                        }
                        .padding(.top, 10)
                    } else {
                        Text("No car selected")
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.top, 40)
                    }

                    Divider()
                        .overlay(Color.cyan.opacity(0.3))
                        .padding(.horizontal, 60)

                    // 📊 Следующее ТО
                    if let next = getNextService(for: selectedCar.first) {
                        VStack(spacing: 10) {
                            Text("Next Service Due:")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.8))

                            Text("\(next.mileage) km • \(formatDate(next.date))")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color(hex: "#FFD54F"))
                                .shadow(color: .yellow.opacity(0.5), radius: 8)
                        }
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(16)
                        .padding(.horizontal, 40)
                        .shadow(color: .cyan.opacity(0.3), radius: 8)
                    }

                    // 🧾 Последние сервисы
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent Services")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.leading, 20)

                        if recentServices(for: selectedCar.first).isEmpty {
                            Text("No service records yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.leading, 20)
                        } else {
                            ForEach(recentServices(for: selectedCar.first)) { record in
                                HStack(spacing: 16) {
                                    Image(systemName: iconForType(record.type ?? ""))
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 20))
                                        .shadow(color: .yellow.opacity(0.5), radius: 5)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(record.type ?? "Unknown")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)

                                        Text("\(record.mileage) km • \(formatDate(record.date))")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.7))
                                    }

                                    Spacer()
                                }
                                .padding()
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(16)
                                .shadow(color: .cyan.opacity(0.2), radius: 6)
                                .padding(.horizontal, 20)
                            }
                        }
                    }

                    Spacer(minLength: 40)

                    // ➕ Добавить сервис
                    NeonButton(title: "Add Service Record") {
                        showAddService = true
                    }
                    .sheet(isPresented: $showAddService) {
                        AddServiceView()
                            .environment(\.managedObjectContext, viewContext)
                    }

                    // 🚪 Logout
                    Button {
                        withAnimation { isLoggedIn = false }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Logout")
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(30)
                        .shadow(color: .yellow.opacity(0.5), radius: 10, y: 6)
                    }
                    .padding(.horizontal, 60)
                    .padding(.bottom, 60)
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(currentName: $currentUserName, currentEmail: $currentUserEmail)
        }
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func iconForType(_ type: String) -> String {
        switch type {
        case "Oil": return "oil.drop.fill"
        case "Tires": return "circle.grid.cross"
        case "Fluids": return "thermometer.snowflake"
        case "Battery": return "bolt.car.fill"
        case "Brakes": return "car.rear.waves.up"
        default: return "wrench.and.screwdriver"
        }
    }

    private func recentServices(for car: Car?) -> [ServiceRecord] {
        guard let car else { return [] }
        return allRecords.filter { $0.car == car }.prefix(3).map { $0 }
    }

    private func getNextService(for car: Car?) -> (mileage: Int32, date: Date)? {
        guard let car else { return nil }
        guard let last = allRecords
            .filter({ $0.car == car })
            .sorted(by: { ($0.date ?? Date()) > ($1.date ?? Date()) })
            .first
        else { return nil }

        return (last.nextServiceKm, last.nextServiceDate ?? Date())
    }
}

#Preview {
    DashboardView(isLoggedIn: .constant(true))
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
