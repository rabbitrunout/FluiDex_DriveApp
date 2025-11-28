import Foundation
import CoreLocation
import Combine
import CoreData

class TripManager: NSObject, ObservableObject, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    @Published var isTracking = false
    @Published var totalDistance: Double = 0
    @Published var duration: TimeInterval = 0
    @Published var lastLocation: CLLocation?
    @Published var currentSpeedKmh: Double = 0

    private var timer: AnyCancellable?

    private let viewContext: NSManagedObjectContext
    private let car: Car

    init(context: NSManagedObjectContext, car: Car) {
        self.viewContext = context
        self.car = car
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5
    }

    func start() {
        totalDistance = 0
        duration = 0
        lastLocation = nil
        isTracking = true

        manager.startUpdatingLocation()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.duration += 1
            }
    }

    func stop() {
        isTracking = false
        manager.stopUpdatingLocation()
        timer?.cancel()

        guard totalDistance > 20 else { return }

        saveTrip()
    }

    func requestPermissions() {
        manager.requestWhenInUseAuthorization()
    }

    // MARK: — Location Updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking, let new = locations.last else { return }

        currentSpeedKmh = max(new.speed * 3.6, 0)

        if let last = lastLocation {
            let d = new.distance(from: last)
            if d > 2 { totalDistance += d }
        }

        lastLocation = new
    }

    private func saveTrip() {
        let trip = Trip(context: viewContext)
        trip.id = UUID()
        trip.date = Date()
        trip.distance = totalDistance
        trip.car = car

        // обновляем пробег
        car.mileage += Int32(totalDistance / 1000)

        try? viewContext.save()
        
        

        // 🔥 Firebase
        FirebaseSyncManager.shared.syncTrip(trip, car: car)
        FirebaseSyncManager.shared.syncCarMileage(car)
    }
    
    // MARK: - Public API для вью (под твой стиль)

    func startTrip() {
        start()
    }

    func stopTrip() {
        stop()
    }

}
