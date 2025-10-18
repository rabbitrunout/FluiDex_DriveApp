import SwiftUI

struct ActionButton: View {
    var title: String
    var icon: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.black)
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.6), radius: 10, y: 4)
        }
    }
}

#Preview("ActionButton Preview") {
    ActionButton(
        title: "Add Service",
        icon: "plus.circle.fill",
        color: Color(hex: "#FFD54F")
    ) {
        print("Tapped")
    }
    .padding()
    .background(Color.black)
}
