import SwiftUI

struct DashboardView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // 🚗 Фото автомобиля
                    Image("BMWX5") // пример
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .shadow(color: .cyan.opacity(0.5), radius: 12, y: 6)

                    // 🔹 Инфо-карточка
                    VStack(alignment: .leading, spacing: 10) {
                        Text("BMW X5 — 2022")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Text("Mileage: 12,000 km")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Next Service: in 800 km")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(20)
                    .shadow(color: .cyan.opacity(0.3), radius: 10, y: 4)
                    .padding(.horizontal)

                    // 💛 Кнопка добавления
                    Button(action: {
                        print("Add new service tapped")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add New Service")
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(25)
                        .shadow(color: .yellow.opacity(0.5), radius: 10, y: 5)
                    }
                    .padding(.horizontal, 50)
                }
                .padding(.top, 40)
            }
        }
    }
}

#Preview {
    DashboardView()
}
