// LaunchScreenView.swift
// FaithForge
//
// Animated launch screen with cross icon, app name, and fade transition.

import SwiftUI

struct LaunchScreenView: View {
    @State private var crossScale: CGFloat = 0.5
    @State private var crossOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringsRotation: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color("FaithBlue").opacity(0.15),
                    Color("BackgroundPrimary"),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Animated cross with ring halos
                ZStack {
                    // Outer ring (Mission)
                    Circle()
                        .stroke(Color("FaithWarm").opacity(0.3), lineWidth: 3)
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringsRotation))

                    // Middle ring (Communion)
                    Circle()
                        .stroke(Color("FaithGreen").opacity(0.4), lineWidth: 3)
                        .frame(width: 110, height: 110)
                        .rotationEffect(.degrees(-ringsRotation * 0.7))

                    // Inner ring (Word)
                    Circle()
                        .stroke(Color("FaithBlue").opacity(0.5), lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(ringsRotation * 0.5))

                    // Cross
                    Image(systemName: "cross.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("FaithBlue"), Color("FaithGreen")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(crossScale)
                        .opacity(crossOpacity)
                }

                // App name
                VStack(spacing: 4) {
                    Text("FaithForge")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color("TextPrimary"))

                    Text("Forge Holy Habits")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(textOpacity)

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                crossScale = 1.0
                crossOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                ringsRotation = 360
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
