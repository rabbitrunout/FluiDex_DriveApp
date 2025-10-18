import SwiftUI

struct CarSelectionView: View {
    @Binding var hasSelectedCar: Bool
    @AppStorage("selectedCar") private var selectedCar: String = ""

    let cars = ["Tesla Model 3", "BMW i4", "Audi e-tron", "Ford Mustang Mach-E", "Hyundai Ioniq 6"]

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Select Your Vehicle")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.7), radius: 8)

                ScrollView {
                    ForEach(cars, id: \.self) { car in
                        Button {
                            withAnimation(.easeInOut(duration: 0.4)) {
                                selectedCar = car
                                hasSelectedCar = true
                            }
                        } label: {
                            HStack {
                                Image(systemName: "car.fill")
                                    .font(.title2)
                                    .foregroundColor(.yellow)
                                Text(car)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                            .shadow(color: .cyan.opacity(0.3), radius: 8)
                            .padding(.horizontal, 20)
                        }
                    }
                }
                Spacer()
            }
            .padding(.top, 40)
        }
    }
}

#Preview {
    CarSelectionView(hasSelectedCar: .constant(false))
}
