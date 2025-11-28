//
//  ProgressCircleView.swift
//  FluiDex Drive
//
//  Created by Irina Saf on 2025-09-26.
//


import SwiftUI

struct ProgressCircleView: View {
    var title: String
    var progress: CGFloat
    var color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(lineWidth: 10)
                    .opacity(0.2)
                    .foregroundColor(color)
                
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                    .foregroundColor(color)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut, value: progress)
                
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 90, height: 90)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        ProgressCircleView(title: "Oil", progress: 0.8, color: .yellow)
        ProgressCircleView(title: "Coolant", progress: 0.6, color: .blue)
        ProgressCircleView(title: "Brake", progress: 0.95, color: .red)
    }
    .padding()
    .background(Color.black)
}

