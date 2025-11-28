import SwiftUI
import CoreData

struct TripTrackingView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [],
        predicate: NSPredicate(format: "isSelected == true")
    ) private var selectedCar: FetchedResults<Car>

    @StateObject private var tripManager: TripManager

    init() {
        // 🧪 временный init, берём активную машину или создаём заглушку
        let context = PersistenceController.shared.container.viewContext
        let carRequest: NSFetchRequest<Car> = Car.fetchRequest()
        carRequest.predicate = NSPredicate(format: "isSelected == true")
        
        let car = (try? context.fetch(carRequest).first) ?? Car(context: context)
        _tripManager = StateObject(wrappedValue: TripManager(context: context, car: car))
    }

    var body: some View {
        VStack(spacing: 30) {
            Text("Trip Distance")
                .font(.title2.bold())
                .foregroundColor(.white)

            Text(String(format: "%.2f km", tripManager.totalDistance / 1000))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.cyan)

            HStack {
                Button("Start Trip") {
                    tripManager.requestPermissions()
                    tripManager.startTrip()   // ✅ теперь всё ок
                }
                .buttonStyle(.borderedProminent)

                Button("Stop") {
                    tripManager.stopTrip()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.black, Color(hex: "#1A1A40")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    TripTrackingView()
}
