import SwiftUI

struct WelcomeAnimationView: View {
    @Binding var showWelcome: Bool
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool

    @AppStorage("userName") private var userName: String = "Driver"

    @State private var animateCar = false
    @State private var animateText = false
    @State private var fadeOut = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(hex: "#1A1A40"),
                    Color(hex: "#001F3F")
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .hueRotation(.degrees(animateText ? 15 : -15))
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateText)

            VStack(spacing: 30) {
                Spacer()

                Text("Welcome back, \(userName)!")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(Color(hex: "#FFD54F"))
                    .shadow(color: .cyan.opacity(0.8), radius: 15, y: 8)
                    .opacity(animateText ? 1 : 0)
                    .scaleEffect(animateText ? 1 : 0.8)
                    .animation(.easeOut(duration: 0.8).delay(0.2), value: animateText)

                Image(systemName: "car.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 60)
                    .foregroundColor(.cyan)
                    .shadow(color: .cyan.opacity(0.8), radius: 15, y: 6)
                    .offset(x: animateCar ? 0 : -400)
                    .rotationEffect(.degrees(animateCar ? 0 : -15))
                    .animation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.6), value: animateCar)

                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.cyan.opacity(0.7), .clear],
                            startPoint: .center,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: animateCar ? 140 : 0, height: 4)
                    .opacity(animateCar ? 1 : 0)
                    .animation(.easeInOut(duration: 0.6).delay(1.0), value: animateCar)

                Spacer()
            }
            .opacity(fadeOut ? 0 : 1)
        }
        .onAppear {
            // ✅ чтобы анимация корректно повторялась каждый раз
            animateCar = false
            animateText = false
            fadeOut = false

            // запуск
            withAnimation { animateText = true }
            withAnimation { animateCar = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    fadeOut = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showWelcome = false
                    // ❌ НЕ трогаем isLoggedIn тут
                }
            }
        }
    }
}

#Preview {
    WelcomeAnimationView(
        showWelcome: .constant(true),
        isLoggedIn: .constant(true),
        hasSelectedCar: .constant(true)
    )
}
