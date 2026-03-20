// StreakFlameView.swift
// FaithForge
//
// Animated flame icon with streak counter.

import SwiftUI

struct StreakFlameView: View {
    let streak: Int
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: streak > 0 ? "flame.fill" : "flame")
                .font(.system(size: 28))
                .foregroundStyle(
                    streak > 0
                        ? LinearGradient(
                            colors: [Color("FaithWarm"), Color("FaithGold")],
                            startPoint: .bottom,
                            endPoint: .top
                          )
                        : LinearGradient(
                            colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                            startPoint: .bottom,
                            endPoint: .top
                          )
                )
                .symbolEffect(.pulse.wholeSymbol, options: .repeating, isActive: streak > 0 && isAnimating)
                .scaleEffect(isAnimating && streak > 0 ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text("\(streak)")
                .font(.caption.bold())
                .foregroundStyle(streak > 0 ? Color("FaithWarm") : .secondary)
        }
        .onAppear { isAnimating = true }
        .accessibilityLabel("\(streak) day streak")
    }
}

#Preview {
    HStack(spacing: 32) {
        StreakFlameView(streak: 0)
        StreakFlameView(streak: 7)
        StreakFlameView(streak: 30)
    }
    .padding()
}
