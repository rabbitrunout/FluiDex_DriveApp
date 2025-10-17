import SwiftUI

struct DeleteAnimationOverlay: View {
    @Binding var show: Bool
    @State private var carOffset: CGFloat = -300
    @State private var opacity: Double = 0
    @State private var showText = false

    var body: some View {
        ZStack {
            if show {
                ZStack {
                    // 🚗 Машинка
                    Image(systemName: "car.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 50)
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.8), radius: 12, y: 5)
                        .offset(x: carOffset, y: -20)
                        .blur(radius: opacity * 2)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.9)) {
                                carOffset = 300
                                opacity = 1
                            }
                            withAnimation(.easeOut(duration: 0.5).delay(1.0)) {
                                showText = true
                            }
                            withAnimation(.easeOut(duration: 0.8).delay(2.0)) {
                                show = false
                            }
                        }

                    // 💨 Пыль после проезда
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [Color.yellow.opacity(0.5), .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 220, height: 120)
                        .blur(radius: 30)
                        .offset(x: carOffset - 50, y: 10)
                        .opacity(opacity)

                    // ✨ Текст Deleted
                    if showText {
                        Text("Deleted ✓")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.8), radius: 10)
                            .transition(.opacity.combined(with: .scale))
                            .offset(y: 40)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: show)
    }
}
