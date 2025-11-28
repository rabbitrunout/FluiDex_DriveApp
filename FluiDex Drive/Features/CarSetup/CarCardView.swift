import SwiftUI

struct CarCardView: View {
    let car: CarModel
    let selectedCarName: String

    @State private var glow = false

    var body: some View {
        VStack(spacing: 10) {
            Image(car.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 100)
                .cornerRadius(12)
                .shadow(color: glowColor.opacity(0.7), radius: glow ? 18 : 8)
                .scaleEffect(glow ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: glow
                )

            Text(car.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(glowColor, lineWidth: 2)
                )
        )
        .shadow(color: glowColor.opacity(0.3), radius: 8)
        .onAppear {
            if car.name == selectedCarName {
                glow = true
            }
        }
    }

    private var glowColor: Color {
        car.name == selectedCarName ? Color(hex: "#FFD54F") : .clear
    }
}

#Preview {
    CarCardView(
        car: CarModel(name: "Audi Q5", imageName: "cars/Audi Q5"),
        selectedCarName: "Audi Q5"
    )
}
