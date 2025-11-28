import Foundation
import CoreLocation
import Combine

class TripLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    @Published var isTracking: Bool = false
    @Published var totalDistance: Double = 0       // в метрах
    @Published var lastLocation: CLLocation?
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10                 // обновление каждые ~10 м
    }
    
    // запрашиваем разрешения
    func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startTrip() {
        totalDistance = 0
        lastLocation = nil
        isTracking = true
        manager.startUpdatingLocation()
    }
    
    func stopTrip() {
        isTracking = false
        manager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location authorized ✅")
        case .denied, .restricted:
            print("Location denied ❌")
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking,
              let newLocation = locations.last,
              newLocation.horizontalAccuracy > 0
        else { return }
        
        if let last = lastLocation {
            let distance = newLocation.distance(from: last) // в метрах
            if distance > 1 { // фильтр шума
                totalDistance += distance
            }
        }
        lastLocation = newLocation
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
