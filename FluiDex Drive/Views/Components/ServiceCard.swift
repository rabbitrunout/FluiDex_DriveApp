import SwiftUI

struct ServiceCard: View {
    var icon: String
    var title: String
    var subtitle: String
    var mileage: String
    var color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
                .shadow(color: color.opacity(0.8), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                Text(mileage)
                    .font(.caption)
                    .foregroundColor(color)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(color.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.3), radius: 10, y: 5)
    }
}

#Preview("ServiceCard Preview") {
    ServiceCard(
        icon: "wrench.and.screwdriver",
        title: "Oil Change",
        subtitle: "Replaced filter and synthetic oil",
        mileage: "Mileage: 85,200 km",
        color: Color(hex: "#FFD54F")
    )
    .padding()
    .background(Color.black)
}
