// AppIconView.swift
// FaithForge
//
// Programmatic app icon design for screenshot / export.
// Render this at 1024x1024 to create the App Store icon.

import SwiftUI

struct AppIconView: View {
    var size: CGFloat = 1024

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.38, blue: 0.62), // Deep blue
                    Color(red: 0.15, green: 0.50, blue: 0.55), // Teal
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial glow
            RadialGradient(
                colors: [
                    Color.white.opacity(0.15),
                    Color.clear,
                ],
                center: .center,
                startRadius: size * 0.05,
                endRadius: size * 0.45
            )

            // Three Faith Rings
            ZStack {
                // Outer ring (Mission) — warm orange
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        Color(red: 0.95, green: 0.55, blue: 0.35),
                        style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round)
                    )
                    .frame(width: size * 0.65, height: size * 0.65)
                    .rotationEffect(.degrees(-90))

                // Middle ring (Communion) — green
                Circle()
                    .trim(from: 0, to: 0.90)
                    .stroke(
                        Color(red: 0.40, green: 0.78, blue: 0.60),
                        style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round)
                    )
                    .frame(width: size * 0.48, height: size * 0.48)
                    .rotationEffect(.degrees(-90))

                // Inner ring (Word) — light blue
                Circle()
                    .trim(from: 0, to: 0.95)
                    .stroke(
                        Color(red: 0.50, green: 0.75, blue: 0.95),
                        style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round)
                    )
                    .frame(width: size * 0.31, height: size * 0.31)
                    .rotationEffect(.degrees(-90))
            }

            // Center cross
            Image(systemName: "cross.fill")
                .font(.system(size: size * 0.12, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: size * 0.01)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

#Preview {
    AppIconView(size: 300)
        .padding()
}
