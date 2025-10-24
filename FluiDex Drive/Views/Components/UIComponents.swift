import SwiftUI

// MARK: - 💛 Glowing Text Field
func glowingField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .foregroundColor(Color(hex: "#FFD54F"))
            .shadow(color: .yellow.opacity(0.8), radius: 8)

        TextField("", text: text)
            .placeholder(when: text.wrappedValue.isEmpty) {
                Text(placeholder).foregroundColor(.white.opacity(0.4))
            }
            .foregroundColor(.white)
            .font(.system(size: 16, weight: .semibold))
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .accentColor(.cyan)
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                LinearGradient(
                    colors: [.cyan.opacity(0.7), .blue.opacity(0.5)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
            )
            .shadow(color: .cyan.opacity(0.6), radius: 4)
    )
    .cornerRadius(12)
    .padding(.horizontal, 8)
}


// MARK: - 🔒 Glowing Secure Field (с кнопкой "показать/скрыть пароль")
// MARK: - 🔒 Glowing Secure Field with Eye Toggle 👁
struct GlowingSecureField: View {
    let placeholder: String
    let icon: String
    @Binding var text: String

    @FocusState private var isFocused: Bool
    @State private var isPasswordVisible: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .frame(width: 24)
                .shadow(color: .yellow.opacity(0.8), radius: 6)

            Group {
                if isPasswordVisible {
                    TextField("", text: $text)
                        .focused($isFocused)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.4))
                        }
                        .textContentType(.newPassword)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(.white)
                        .accentColor(.cyan)
                } else {
                    SecureField("", text: $text)
                        .focused($isFocused)
                        .placeholder(when: text.isEmpty) {
                            Text(placeholder).foregroundColor(.white.opacity(0.4))
                        }
                        .textContentType(.newPassword)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(.white)
                        .accentColor(.cyan)
                }
            }

            // 👁 Toggle button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isPasswordVisible.toggle()
                }
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(isFocused ? .cyan : .gray.opacity(0.6))
                    .shadow(color: isFocused ? .cyan.opacity(0.8) : .clear, radius: 5)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        colors: isFocused
                            ? [.cyan.opacity(0.9), .blue.opacity(0.8)]
                            : [.cyan.opacity(0.5), .blue.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isFocused ? 2 : 1.4
                )
                .shadow(color: isFocused ? .cyan.opacity(0.9) : .cyan.opacity(0.5), radius: 6)
        )
        .cornerRadius(12)
        .padding(.horizontal, 8)
        .animation(.easeInOut(duration: 0.3), value: isFocused)
    }
}


// MARK: - 🎚 Glowing Picker
func glowingPicker(_ title: String, selection: Binding<String>, options: [String], icon: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "#FFD54F"))
                .shadow(color: .yellow.opacity(0.8), radius: 8)

            Picker(title, selection: selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).foregroundColor(.white)
                }
            }
            .pickerStyle(.segmented)
            .colorMultiply(Color(hex: "#FFD54F"))
        }
    }
    .padding()
    .background(Color.white.opacity(0.05))
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
            .shadow(color: .cyan.opacity(0.6), radius: 4)
    )
    .cornerRadius(12)
    .padding(.horizontal, 8)
}

// MARK: - 💡 Placeholder Helper
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

    func glow(color: Color = .cyan, radius: CGFloat = 20) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius / 2)
            .shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius * 2)
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

// MARK: - ⚡ Neon Button
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

#Preview {
    ZStack {
        LinearGradient(
            gradient: Gradient(colors: [.black, Color(hex: "#1A1A40")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 20) {
            GlowingSecureField(placeholder: "Password", icon: "lock.fill", text: .constant(""))
            GlowingSecureField(placeholder: "Confirm Password", icon: "checkmark.shield.fill", text: .constant(""))
        }
        .padding()
    }
}
