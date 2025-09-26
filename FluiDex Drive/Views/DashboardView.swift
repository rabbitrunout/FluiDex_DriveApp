import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var viewModel: ServiceViewModel
    
    // Пока задаём текущий пробег вручную
    let currentMileage = 86000
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#0D0D0D"), Color(hex: "#1A1A40")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("My Jeep Compass")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Image("JeepCompass") // картинка из Assets
                    .resizable()
                    .scaledToFit()
                    .frame(height: 150)
                    .shadow(color: .blue.opacity(0.5), radius: 15, x: 0, y: 5)
                
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
                
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Text("+ Add Service")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FFD54F"))
                            .cornerRadius(12)
                    }
                    
                    Button(action: {}) {
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
}

#Preview {
    DashboardView()
        .environmentObject(ServiceViewModel())
}
