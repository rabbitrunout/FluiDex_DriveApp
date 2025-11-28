import SwiftUI

struct TipBanner: View {
    var message: String
    var icon: String = "lightbulb"
    var color: Color = Color(hex: "#FFD54F")

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .shadow(color: color.opacity(0.7), radius: 8, y: 3)

            Text(message)
                .foregroundColor(.white)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.3), radius: 10, y: 5)
    }
}

#Preview("TipBanner Preview") {
    TipBanner(message: "Remember to check your tire pressure every 2 weeks!")
        .padding()
        .background(Color.black)
}
