import SwiftUI
import CoreData

struct TripHUDView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    ) private var selectedCar: FetchedResults<Car>

    @StateObject private var tripManager: TripManager

    init() {
        let context = PersistenceController.shared.container.viewContext
        let car = try? context.fetch(Car.fetchRequest()).first
        _tripManager = StateObject(
            wrappedValue: TripManager(context: context, car: car ?? Car())
        )
    }

    var body: some View {
        VStack(spacing: 12) {

            HStack {
                Text("Trip Tracker")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Circle()
                    .fill(tripManager.isTracking ? .green : .gray)
                    .frame(width: 10, height: 10)
            }

            HStack {
                metric("Distance", "\(String(format: "%.2f", tripManager.totalDistance / 1000)) km")
                Spacer()
                metric("Duration", formatTime(tripManager.duration))
                Spacer()
                metric("Speed", "\(Int(tripManager.currentSpeedKmh)) km/h")
            }

            HStack(spacing: 16) {
                Button {
                    tripManager.requestPermissions()
                    tripManager.start()
                } label: {
                    Label("Start", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button { tripManager.stop() } label: {
                    Label("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding()
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.cyan)
        }
    }

    private func formatTime(_ sec: TimeInterval) -> String {
        let s = Int(sec)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }
}


#Preview {
    ZStack {
        LinearGradient(colors: [.black, Color(hex: "#1A1A40")],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .ignoresSafeArea()

        TripHUDView()
            .padding()
    }
}
