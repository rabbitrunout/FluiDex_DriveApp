import SwiftUI

struct ServiceLogView: View {
    @State private var selectedCategory: String = "All"

    // 🔧 Список сервисных записей
    let services = [
        ("Oil Change", "25,200 km • Next in 1,200 km", "oil.drop.fill", "Oil"),
        ("Tire Rotation", "26,800 km • Done 2 weeks ago", "circle.grid.cross", "Tires"),
        ("Brake Inspection", "27,000 km • Scheduled", "wrench.and.screwdriver.fill", "Other"),
        ("Coolant Check", "24,000 km • Next in 2,000 km", "thermometer.snowflake", "Fluids")
    ]
    
    // 🔹 Категории
    let categories = ["All", "Oil", "Tires", "Fluids", "Other"]
    
    var body: some View {
        ZStack {
            // 🌌 Фон — тёмный неоновый
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                // 🏁 Заголовок
                Text("Service Log")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 8, y: 4)
                    .padding(.top, 30)

                // 🟡 Категории
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(categories, id: \.self) { category in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    selectedCategory = category
                                }
                            }) {
                                Text(category)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedCategory == category ? .black : .white)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 20)
                                    .background(
                                        selectedCategory == category
                                        ? Color(hex: "#FFD54F")
                                        : Color.white.opacity(0.08)
                                    )
                                    .cornerRadius(25)
                                    .shadow(color: selectedCategory == category ? Color.yellow.opacity(0.4) : .clear, radius: 8, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                // 🔧 Карточки сервисов
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(filteredServices(), id: \.0) { service in
                            HStack(spacing: 16) {
                                Image(systemName: service.2)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 36, height: 36)
                                    .foregroundColor(.yellow)
                                    .shadow(color: .yellow.opacity(0.5), radius: 8, y: 4)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(service.0)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text(service.1)
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(16)
                            .shadow(color: .cyan.opacity(0.3), radius: 10, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 0.8)
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 80)
                }

                Spacer()

                // ➕ Кнопка "Add Service"
                Button(action: {
                    print("Add Service tapped")
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22, weight: .bold))
                        Text("Add Service")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(hex: "#FFD54F"))
                    .cornerRadius(30)
                    .shadow(color: Color.yellow.opacity(0.4), radius: 10, y: 6)
                    .padding(.horizontal, 60)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // 🔹 Фильтр по категориям
    func filteredServices() -> [(String, String, String, String)] {
        if selectedCategory == "All" {
            return services
        } else {
            return services.filter { $0.3 == selectedCategory }
        }
    }
}

#Preview {
    ServiceLogView()
}
