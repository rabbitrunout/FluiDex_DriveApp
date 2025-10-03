import SwiftUI

struct TipBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            
            Text(message)
                .font(.footnote)
                .foregroundColor(.black)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 3)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color(hex: "#FFE082").ignoresSafeArea()
        TipBanner(message: "💡 Tip: Check your oil dipstick once a month for peace of mind.")
    }
}
