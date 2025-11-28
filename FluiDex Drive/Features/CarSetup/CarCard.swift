import SwiftUI

struct CarCard: View {
    var title: String
    var imageName: String
    var description: String
    var colorHex: String
    var onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // 🚙 Фото авто
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 70)
                    .shadow(color: Color(hex: colorHex).opacity(0.6), radius: 10, y: 4)
                
                // 🧾 Текст
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                }
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(hex: colorHex).opacity(0.3))
            .cornerRadius(20)
            .shadow(color: Color(hex: colorHex).opacity(0.5), radius: 8, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(hex: colorHex).opacity(0.5), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CarCard(
        title: "Jeep Compass",
        imageName: "JeepCompass",
        description: "Adventure-ready compact SUV",
        colorHex: "#FF7043",
        onSelect: {}
    )
}
