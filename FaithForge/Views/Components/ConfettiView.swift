// ConfettiView.swift
// FaithForge
//
// Reusable confetti/celebration overlay for level-ups, ring closures, and badge unlocks.

import SwiftUI

// MARK: - Confetti Overlay Modifier

struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool
    var particleCount: Int = 50
    var colors: [Color] = [
        Color("FaithBlue"), Color("FaithGreen"),
        Color("FaithGold"), Color("FaithWarm"),
        .white, .yellow,
    ]

    @State private var particles: [ConfettiParticle] = []
    @State private var animationPhase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                if isActive {
                    GeometryReader { geo in
                        ZStack {
                            ForEach(particles) { particle in
                                particle.shape
                                    .fill(particle.color)
                                    .frame(width: particle.size, height: particle.size * particle.aspectRatio)
                                    .rotationEffect(.degrees(particle.rotation + Double(animationPhase) * particle.rotationSpeed))
                                    .position(
                                        x: particle.startX * geo.size.width,
                                        y: particle.startY + animationPhase * (geo.size.height + 40) * particle.speed
                                    )
                                    .opacity(Double(max(1.0 - animationPhase * 0.8, 0)))
                            }
                        }
                    }
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    generateParticles()
                    withAnimation(.easeIn(duration: 2.5)) {
                        animationPhase = 1.0
                    }
                    // Auto-dismiss
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isActive = false
                        animationPhase = 0
                        particles = []
                    }
                }
            }
    }

    private func generateParticles() {
        particles = (0..<particleCount).map { _ in
            ConfettiParticle(
                color: colors.randomElement() ?? .yellow,
                size: CGFloat.random(in: 6...14),
                aspectRatio: CGFloat.random(in: 0.5...2.0),
                startX: CGFloat.random(in: 0...1),
                startY: CGFloat.random(in: -80...(-20)),
                speed: CGFloat.random(in: 0.6...1.2),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 100...500),
                shapeType: Int.random(in: 0...2)
            )
        }
        animationPhase = 0
    }
}

// MARK: - Particle Model

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let aspectRatio: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let rotation: Double
    let rotationSpeed: Double
    let shapeType: Int

    var shape: some ShapeStyle & Shape {
        switch shapeType {
        case 0: return AnyShape(Rectangle())
        case 1: return AnyShape(Circle())
        default: return AnyShape(Capsule())
        }
    }
}

// MARK: - AnyShape wrapper

private struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path

    init<S: Shape>(_ shape: S) {
        pathBuilder = { rect in shape.path(in: rect) }
    }

    func path(in rect: CGRect) -> Path {
        pathBuilder(rect)
    }
}

// MARK: - View Extension

extension View {
    /// Overlay confetti particles when `isActive` becomes true. Auto-dismisses after 2.5s.
    func confetti(isActive: Binding<Bool>, particleCount: Int = 50) -> some View {
        modifier(ConfettiModifier(isActive: isActive, particleCount: particleCount))
    }
}

// MARK: - Level-Up Celebration View

struct LevelUpCelebrationView: View {
    let newLevel: FaithLevel
    let onDismiss: () -> Void

    @State private var showConfetti = false
    @State private var iconScale: CGFloat = 0.3
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: newLevel.icon)
                    .font(.system(size: 72))
                    .foregroundStyle(Color("FaithGold"))
                    .scaleEffect(iconScale)
                    .shadow(color: Color("FaithGold").opacity(0.5), radius: 20)

                VStack(spacing: 8) {
                    Text("LEVEL UP!")
                        .font(.title.bold())
                        .foregroundStyle(Color("FaithGold"))

                    Text("You are now a")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))

                    Text(newLevel.rawValue)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }
                .opacity(textOpacity)

                Button(action: onDismiss) {
                    Text("Continue")
                        .font(.headline)
                        .foregroundStyle(Color("FaithGold"))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                }
                .opacity(textOpacity)
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Level up! You are now a \(newLevel.rawValue)")
        }
        .confetti(isActive: $showConfetti, particleCount: 80)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                iconScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
                textOpacity = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
                HapticManager.shared.levelUp()
                SoundManager.shared.playLevelUp()
            }
        }
    }
}

// MARK: - Ring Closed Celebration

struct RingClosedCelebrationView: View {
    let ringCategory: RingCategory
    let onDismiss: () -> Void

    @State private var ringScale: CGFloat = 0.5
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(ringColor, lineWidth: 12)
                        .frame(width: 120, height: 120)
                        .scaleEffect(ringScale)

                    Image(systemName: "checkmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(ringColor)
                }

                VStack(spacing: 6) {
                    Text("\(ringCategory.rawValue) Ring Closed!")
                        .font(.title2.bold())
                        .foregroundStyle(.white)

                    Text("You hit your daily \(ringCategory.rawValue) goal!")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Button(action: onDismiss) {
                    Text("Awesome!")
                        .font(.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .foregroundStyle(.white)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("\(ringCategory.rawValue) ring closed! You hit your daily \(ringCategory.rawValue) goal.")
        }
        .confetti(isActive: $showConfetti, particleCount: 40)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                ringScale = 1.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showConfetti = true
                HapticManager.shared.ringClosed()
                SoundManager.shared.playRingClosed()
            }
        }
    }

    private var ringColor: Color {
        switch ringCategory {
        case .word:      return Color("FaithBlue")
        case .communion: return Color("FaithGreen")
        case .mission:   return Color("FaithWarm")
        }
    }
}

#Preview("Confetti") {
    @Previewable @State var active = true
    Color.black
        .confetti(isActive: $active)
        .onTapGesture { active = true }
}
