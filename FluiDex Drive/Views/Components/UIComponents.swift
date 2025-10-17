import SwiftUI

// MARK: - 💛 Глобальный стиль полей (неоновые поля с подсветкой)
func glowingField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .foregroundColor(Color(hex: "#FFD54F"))
            .shadow(color: .yellow.opacity(0.8), radius: 8)

        TextField("", text: text)
            .placeholder(when: text.wrappedValue.isEmpty) {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.4))
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
            .shadow(color: .cyan.opacity(0.6), radius: 4)
    )
    .cornerRadius(12)
}

// MARK: - 🔒 Secure Glowing Field
func glowingSecureField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .foregroundColor(Color(hex: "#FFD54F"))
            .shadow(color: .yellow.opacity(0.8), radius: 8)

        SecureField("", text: text)
            .placeholder(when: text.wrappedValue.isEmpty) {
                Text(placeholder)
                    .foregroundColor(.white.opacity(0.4))
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
            .shadow(color: .cyan.opacity(0.6), radius: 4)
    )
    .cornerRadius(12)
}

// MARK: - 💡 Placeholder helper
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - 🎨 HEX Color Support
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")

        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - ⚡️ Неоновая кнопка
struct NeonButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "#FFD54F"))
                .foregroundColor(.black)
                .cornerRadius(30)
                .shadow(color: Color.yellow.opacity(0.6), radius: 10, y: 6)
        }
        .padding(.horizontal, 50)
    }
}
