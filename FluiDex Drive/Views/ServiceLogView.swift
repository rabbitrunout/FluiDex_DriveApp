import SwiftUI

struct ServiceLogView: View {
    @ObservedObject var viewModel: ServiceViewModel
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#FF4081"), Color(hex: "#00E5FF")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Service Log")
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .padding(.top, 20)
                    .padding(.leading, 16)
                
                List(viewModel.services) { service in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(service.type)
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Mileage: \(service.mileage) km")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                            Text(service.date, style: .date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                        Text("$\(Int(service.cost))")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
}

#Preview {
    ServiceLogView(viewModel: ServiceViewModel())
}
