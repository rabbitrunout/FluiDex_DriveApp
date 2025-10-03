import SwiftUI
import CoreData

struct CarSelectionView: View {
    @Binding var hasSelectedCar: Bool
    @Environment(\.managedObjectContext) private var viewContext
    
    // 🔹 Список доступных машин
    let cars = [
        ("BMW", "X5", 2022, 12000, "BMWX5"),
        ("Toyota", "Corolla", 2018, 80000, "ToyotaCorolla"),
        ("Jeep", "Compass", 2020, 45000, "JeepCompass"),
        ("Mazda", "CX-5", 2021, 30000, "system") // system → заглушка
    ]
    
    var body: some View {
        ZStack {
            Color(hex: "#FFE082").ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Select Your Car")
                    .font(.title.bold())
                    .foregroundColor(.red)
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(cars, id: \.1) { car in
                            Button(action: {
                                saveCar(make: car.0, model: car.1, year: car.2, mileage: car.3, imageName: car.4)
                                hasSelectedCar = true
                            }) {
                                HStack {
                                    if car.4 == "system" {
                                        Image(systemName: "car.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 60, height: 40)
                                            .foregroundColor(.white)
                                            .padding(.trailing, 8)
                                    } else {
                                        Image(car.4) // PNG в Assets
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 80, height: 50)
                                            .padding(.trailing, 8)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text("\(car.0) \(car.1)")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                        Text("Year \(car.2)")
                                            .font(.subheadline)
                                            .foregroundColor(.black.opacity(0.7))
                                    }
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color(hex: "#FF7043"))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.15), radius: 5, y: 3)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // 🔹 Сохраняем выбранную машину в CoreData
    private func saveCar(make: String, model: String, year: Int, mileage: Int, imageName: String) {
        let newCar = Car(context: viewContext)
        newCar.id = UUID()
        newCar.make = make
        newCar.model = model
        newCar.year = Int16(year)
        newCar.mileage = Int32(mileage)
        newCar.imageName = imageName // 🔥 сохраним PNG/asset имя
        
        do {
            try viewContext.save()
            print("✅ Car saved: \(make) \(model) with image \(imageName)")
        } catch {
            print("❌ Error saving car: \(error.localizedDescription)")
        }
    }
}



#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
}
