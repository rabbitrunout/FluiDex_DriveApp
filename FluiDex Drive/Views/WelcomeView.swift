import SwiftUI

struct WelcomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                Image("JeepCompass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220, height: 150)
                
                Text("Welcome to")
                    .font(.title2)
                    .foregroundColor(.white)
                Text("FluiDex Drive")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    isLoggedIn = true
                }) {
                    Text("Get Started")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(25)
                        .shadow(color: .yellow.opacity(0.5), radius: 8, y: 3)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

#Preview {
    WelcomeView(isLoggedIn: .constant(false), hasSelectedCar: .constant(false))
}
