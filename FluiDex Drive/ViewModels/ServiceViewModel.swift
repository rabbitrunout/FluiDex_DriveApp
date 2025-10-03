import SwiftUI
import Combine

struct ServiceEntry: Identifiable, Codable {
    let id: UUID
    let type: String
    let date: Date
    let mileage: Int
    let note: String?
    
    init(type: String, date: Date, mileage: Int, note: String? = nil) {
        self.id = UUID()
        self.type = type
        self.date = date
        self.mileage = mileage
        self.note = note
    }
}

class ServiceViewModel: ObservableObject {
    @Published var services: [ServiceEntry] {
        didSet { saveServices() }
    }
    
    private let key = "savedServices"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ServiceEntry].self, from: data) {
            self.services = decoded
        } else {
            self.services = []
        }
    }
    
    func addService(type: String, date: Date, mileage: Int, note: String? = nil) {
        let newService = ServiceEntry(type: type, date: date, mileage: mileage, note: note)
        services.append(newService)
    }
    
    func deleteService(at offsets: IndexSet) {
        services.remove(atOffsets: offsets)
    }
    
    private func saveServices() {
        if let encoded = try? JSONEncoder().encode(services) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
