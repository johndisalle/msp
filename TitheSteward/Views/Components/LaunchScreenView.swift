import SwiftUI

struct LaunchScreenView: View {
    @State private var iconScale: CGFloat = 0.5
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            Color("BackgroundPrimary")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    // Glow effect
                    Circle()
                        .fill(Color("AccentGold").opacity(0.15))
                        .frame(width: 160, height: 160)
                        .blur(radius: 20)
                        .opacity(glowOpacity)

                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AccentGold"), Color("AccentGold").opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: Color("AccentGold").opacity(0.3), radius: 16, y: 8)

                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)
                }

                VStack(spacing: 8) {
                    Text("Tithe Steward")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Tithe First, Steward Faithfully")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                textOpacity = 1.0
                glowOpacity = 1.0
            }
        }
    }
}

#Preview {
    LaunchScreenView()
}
