// FaithRingsView.swift
// FaithForge
//
// Three concentric Faith Rings (Word, Communion, Mission) that fill based on daily XP.

import SwiftUI

struct FaithRingsView: View {
    @Bindable var xpManager: XPManager

    /// Ring configurations from outermost to innermost.
    private let ringConfigs: [(category: RingCategory, color: Color, size: CGFloat)] = [
        (.word,      Color("FaithBlue"),  140),
        (.communion, Color("FaithGreen"), 105),
        (.mission,   Color("FaithWarm"),  70),
    ]

    var body: some View {
        HStack(spacing: 24) {
            // Rings visual
            ZStack {
                ForEach(ringConfigs, id: \.category) { config in
                    let progress = xpManager.ringProgress(for: config.category)
                    ringArc(
                        fraction: progress.fillFraction,
                        color: config.color,
                        size: config.size
                    )
                }
            }
            .frame(width: 160, height: 160)

            // Ring labels
            VStack(alignment: .leading, spacing: 12) {
                ForEach(ringConfigs, id: \.category) { config in
                    let progress = xpManager.ringProgress(for: config.category)
                    ringLabel(
                        category: config.category,
                        color: config.color,
                        xp: progress.dailyXP,
                        goal: config.category.dailyGoal
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Ring Arc

    private func ringArc(fraction: Double, color: Color, size: CGFloat) -> some View {
        ZStack {
            // Background track
            Circle()
                .stroke(color.opacity(0.15), lineWidth: 12)
                .frame(width: size, height: size)

            // Fill arc
            Circle()
                .trim(from: 0, to: CGFloat(fraction))
                .stroke(
                    color,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: fraction)
        }
    }

    // MARK: - Ring Label

    private func ringLabel(category: RingCategory, color: Color, xp: Int, goal: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 1) {
                Text(category.rawValue)
                    .font(.caption.bold())
                    .foregroundStyle(Color("TextPrimary"))

                Text("\(xp)/\(goal) XP")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(category.rawValue) ring, \(xp) of \(goal) XP")
    }
}
