import SwiftUI
import CoreData

struct DashboardView: View {
    @FetchRequest(
        entity: Car.entity(),
        sortDescriptors: []
    ) var cars: FetchedResults<Car>
    
    var body: some View {
        ZStack {
            Color(hex: "#FFF59D").ignoresSafeArea()
            
            VStack(spacing: 20) {
                if let car = cars.first {
                    Text("FluiDex Drive")
                        .font(.title.bold())
                        .foregroundColor(.red)
                    
                    Text("My \(car.make ?? "") \(car.model ?? "") \(car.year)")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    Image("BMWX5") // ⚠️ можно динамически
                        .resizable()
                        .scaledToFit()
                        .frame(height: 150)
                        .shadow(color: .blue.opacity(0.5), radius: 15)
                    
                    HStack(spacing: 20) {
                        ProgressCircleMini(title: "Oil", value: 80, subtitle: "1200 km", color: .yellow)
                        ProgressCircleMini(title: "Coolant", value: 60, subtitle: "3000 km", color: .blue)
                        ProgressCircleMini(title: "Brake", value: 40, subtitle: "1500 km", color: .red)
                    }
                } else {
                    Text("No car selected")
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}


#Preview {
    DashboardView()
}
