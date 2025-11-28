//
//  WarningBanner.swift
//  FluiDex Drive
//
//  Created by Irina Saf on 2025-09-26.
//

import SwiftUI

struct WarningBanner: View {
    let title: String
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.black.opacity(0.35))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.yellow.opacity(0.5), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .yellow.opacity(0.25), radius: 10, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        WarningBanner(title: "Service due soon", message: "Oil change recommended within 500 km")
    }
}

