import SwiftUI

struct ProgressCircleMini: View {
    let title: String
    let value: Double   // от 0 до 100
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: CGFloat(value / 100))
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut, value: value)
                
                Text("\(Int(value))%")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 70, height: 70)
            
            Text(title)
                .font(.footnote.bold())
                .foregroundColor(.white)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack {
            ProgressCircleMini(title: "Oil", value: 80, subtitle: "1200 km", color: .yellow)
            ProgressCircleMini(title: "Coolant", value: 60, subtitle: "3000 km", color: .blue)
            ProgressCircleMini(title: "Brake", value: 40, subtitle: "1500 km", color: .red)
        }
    }
}
