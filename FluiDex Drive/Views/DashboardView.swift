import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: ServiceViewModel
    
    // Пока текущий пробег задаём вручную/заглушкой
    let currentMileage = 86_000
    let warnThreshold = 0.20
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0D0D"), Color(hex: "#1A1A40")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 18) {
                // Заголовок
                Text("My Jeep Compass")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // 🔔 Баннер при необходимости
                if let due = viewModel.mostCriticalDue(currentMileage: currentMileage),
                   due.progress < warnThreshold {
                    
                    WarningBanner(
                        title: "Service due soon",
                        message: bannerMessage(for: due)
                    )
                }
                
                // Машинка
                Image("JeepCompass") // добавь PNG в Assets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 5)
                
                // Прогресс-бары
                HStack(spacing: 20) {
                    ProgressCircleView(
                        title: "Oil",
                        progress: viewModel.progress(for: "Oil", currentMileage: currentMileage),
                        color: .yellow
                    )
                    ProgressCircleView(
                        title: "Coolant",
                        progress: viewModel.progress(for: "Coolant", currentMileage: currentMileage),
                        color: .blue
                    )
                    ProgressCircleView(
                        title: "Brake",
                        progress: viewModel.progress(for: "Brake", currentMileage: currentMileage),
                        color: .red
                    )
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Кнопки действий
                HStack(spacing: 20) {
                    Button(action: {
                        // Навигация на Add Service (если у тебя TabView — можно переключать таб)
                    }) {
                        Text("+ Add Service")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FFD54F"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Навигация на Service Log
                    }) {
                        Text("Service Log")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }
    
    private func bannerMessage(for due: ServiceViewModel.DueInfo) -> String {
        let typeReadable: String
        switch due.type {
        case "Oil":     typeReadable = "Oil change"
        case "Coolant": typeReadable = "Coolant service"
        case "Brake":   typeReadable = "Brake fluid service"
        default:        typeReadable = "\(due.type) service"
        }
        
        // Пример сообщения от оставшегося километража
        if due.etaKm == 0 {
            return "\(typeReadable) required now"
        } else if due.etaKm <= 500 {
            return "\(typeReadable) recommended within \(due.etaKm) km"
        } else {
            return "\(typeReadable) due in ~\(due.etaKm) km"
        }
    }
}

#Preview {
    DashboardView()
        .environmentObject(ServiceViewModel())
}
