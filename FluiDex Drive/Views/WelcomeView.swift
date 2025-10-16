import SwiftUI

struct WelcomeView: View {
    @Binding var isLoggedIn: Bool
    @Binding var hasSelectedCar: Bool
    @Binding var showLogin: Bool

    var body: some View {
        ZStack {
            // 🖤 Градиентный фон
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color(hex: "#1A1A40")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                Spacer()

                // 🚙 Изображение автомобиля
                Image("JeepCompass") // добавь в Assets картинку из макета
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 160)
                    .shadow(color: .cyan.opacity(0.4), radius: 20, y: 8)

                // 🩵 Заголовок
                Text("Welcome to")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                Text("FluiDex Drive")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .cyan.opacity(0.6), radius: 10, y: 4)

                Spacer()

                // 💛 Кнопка
                Button(action: {
                    showLogin = true
                }) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "#FFD54F"))
                        .foregroundColor(.black)
                        .cornerRadius(30)
                        .shadow(color: Color.yellow.opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 50)
                .padding(.bottom, 40)

                // 🔹 Подпись с логотипом
                HStack(spacing: 6) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 22)
//                    Text("FluiDex")
//                        .font(.system(size: 14, weight: .semibold))
//                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    WelcomeView(
        isLoggedIn: .constant(false),
        hasSelectedCar: .constant(false),
        showLogin: .constant(false)
    )
}
