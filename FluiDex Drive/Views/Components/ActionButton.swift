import SwiftUI

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.footnote.bold())
                .foregroundColor(.black)
        }
        .frame(width: 80)
    }
}

#Preview {
    HStack(spacing: 20) {
        ActionButton(title: "Log Service", icon: "wrench.fill", color: .orange)
        ActionButton(title: "Expenses", icon: "dollarsign.circle.fill", color: .green)
        ActionButton(title: "Assistant", icon: "questionmark.circle.fill", color: .purple)
    }
    .padding()
    .background(Color(hex: "#FFE082"))
}
