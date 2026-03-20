// XPBarView.swift
// FaithForge
//
// Horizontal progress bar used for XP / level display.

import SwiftUI

struct XPBarView: View {
    let progress: Double // 0.0 – 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                Capsule()
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 10)

                // Fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color("FaithBlue"), Color("FaithGreen")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * CGFloat(progress), 6), height: 10)
                    .animation(.spring(duration: 0.5), value: progress)
            }
        }
        .frame(height: 10)
        .accessibilityLabel("Experience progress \(Int(progress * 100)) percent")
    }
}

#Preview {
    VStack(spacing: 20) {
        XPBarView(progress: 0.0)
        XPBarView(progress: 0.35)
        XPBarView(progress: 0.75)
        XPBarView(progress: 1.0)
    }
    .padding()
}
