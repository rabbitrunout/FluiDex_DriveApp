import Foundation
import CoreLocation
import Combine

/// Модель одной поездки (можно потом связать с Core Data)
struct TripSummary: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let distanceKm: Double
    let duration: TimeInterval
}

/// Менеджер, который считает пробег на основе GPS
final class TripManager: NSObject, ObservableObject {
    // MARK: - Публичные стейты для SwiftUI
    @Published var isTracking: Bool = false
    @Published var distanceKm: Double = 0
    @Published var duration: TimeInterval = 0
    @Published var currentSpeedKmh: Double = 0
    @Published var lastTrip: TripSummary?

    // Можно показывать статус в UI
    @Published var statusText: String = "Idle"

    // MARK: - Приватные свойства
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var startDate: Date?
    private var timer: Timer?

    // Порог, чтобы не считать дрожание GPS как движение
    private let minSpeedKmh: Double = 5.0      // ниже — считаем, что стоим
    private let minDistanceMeters: Double = 5  // отфильтровываем шум

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .automotiveNavigation
        locationManager.pausesLocationUpdatesAutomatically = true
    }

    // MARK: - Публичные методы

    /// Запросить доступ + запустить трекинг
    func start() {
        let status = locationManager.authorizationStatus

        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            statusText = "Requesting Location Access…"
        case .restricted, .denied:
            statusText = "Location access denied"
        case .authorizedAlways, .authorizedWhenInUse:
            beginTracking()
        @unknown default:
            statusText = "Unknown location status"
        }
    }

    /// Остановить поездку вручную
    func stop() {
        guard isTracking else { return }

        locationManager.stopUpdatingLocation()
        timer?.invalidate()
        timer = nil

        let endDate = Date()
        let start = startDate ?? endDate

        let summary = TripSummary(
            startDate: start,
            endDate: endDate,
            distanceKm: distanceKm,
            duration: duration
        )
        lastTrip = summary

        isTracking = false
        statusText = "Trip finished"

        // Сбросим для следующей поездки
        lastLocation = nil
        startDate = nil
        currentSpeedKmh = 0
    }

    // MARK: - Внутренний запуск

    private func beginTracking() {
        distanceKm = 0
        duration = 0
        currentSpeedKmh = 0
        lastLocation = nil
        startDate = Date()

        isTracking = true
        statusText = "Tracking trip…"

        // Запуск GPS
        locationManager.startUpdatingLocation()

        // Таймер для подсчёта длительности
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, self.isTracking, let start = self.startDate else { return }
            self.duration = Date().timeIntervalSince(start)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension TripManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            statusText = "Location Ready"
        case .denied, .restricted:
            statusText = "Location access denied"
        case .notDetermined:
            statusText = "Location not determined"
        @unknown default:
            statusText = "Unknown location status"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        statusText = "Location error: \(error.localizedDescription)"
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isTracking else { return }

        guard let newLocation = locations.last, newLocation.horizontalAccuracy >= 0 else { return }

        // Скорость в м/с → км/ч
        let speedMs = max(newLocation.speed, 0)
        let speedKmh = speedMs * 3.6
        currentSpeedKmh = speedKmh

        // Фильтруем по скорости, чтобы не считать "стояние"
        if speedKmh < minSpeedKmh {
            return
        }

        if let last = lastLocation {
            let delta = newLocation.distance(from: last) // в метрах
            if delta >= minDistanceMeters {
                distanceKm += delta / 1000.0
            }
        }

        lastLocation = newLocation
    }
}
