//
//  WelcomeView.swift
//  FluiDex Drive
//
//  Created by Irina Saf on 2025-09-26.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        ZStack {
            // Фон (градиент)
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#00E5FF"), Color(hex: "#9C27B0")]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Логотип
                Image("AppLogo") // добавь в Assets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .shadow(color: .blue.opacity(0.5), radius: 20, x: 0, y: 0)
                
                // Название
                Text("FluiDex Drive")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 0)
                
                // Подзаголовок
                Text("Smart Vehicle Maintenance Tracker")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
                
                // Кнопка "Get Started"
                Button(action: {
                    // Навигация на Dashboard
                }) {
                    Text("Get Started")
                        .font(.headline.bold())
                        .foregroundColor(.black)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(hex: "#FFD54F"))
                        .cornerRadius(12)
                        .shadow(color: .yellow.opacity(0.7), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 40)
                
                // Кнопка "Log In"
                Button(action: {
                    // Навигация на Log In
                }) {
                    Text("Log In")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.top, 10)
                
                Spacer()
            }
        }
    }
}

#Preview {
    WelcomeView()
}
