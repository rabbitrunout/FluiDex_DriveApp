import SwiftUI

struct ServiceCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let mileage: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .padding(10)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.black.opacity(0.7))
                Text("Mileage: \(mileage) km")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(color.opacity(0.2))
        .cornerRadius(12)
        .shadow(color: color.opacity(0.3), radius: 5, x: 0, y: 3)
    }
}

#Preview {
    VStack(spacing: 16) {
        ServiceCard(
            icon: "drop.fill",
            title: "Oil Change",
            subtitle: "Next in 1,200 km",
            mileage: "25,200",
            color: .red
        )
        
        ServiceCard(
            icon: "wrench.adjustable.fill",
            title: "Inspection",
            subtitle: "Sep 2025",
            mileage: "82,000",
            color: .orange
        )
    }
    .padding()
    .background(Color(hex: "#FFF3CD"))
}
