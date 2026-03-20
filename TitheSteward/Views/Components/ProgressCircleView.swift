import SwiftUI

struct ProgressCircleView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    var color: Color = Color("AccentGold")
    var trackColor: Color = Color(.systemGray5)

    var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)
                .frame(width: size, height: size)

            Circle()
                .trim(from: 0, to: min(1.0, progress))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: progress)
        }
    }
}

struct ScriptureCard: View {
    let verse: String
    let reference: String

    var body: some View {
        VStack(spacing: 8) {
            Text("\"\(verse)\"")
                .font(.callout.italic())
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Text("— \(reference)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color("AccentGold").opacity(0.05))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressCircleView(progress: 0.65, lineWidth: 12, size: 120)

        ScriptureCard(
            verse: "Honor the LORD with your wealth...",
            reference: "Proverbs 3:9"
        )

        EmptyStateView(
            icon: "heart.slash",
            title: "No giving yet",
            subtitle: "Start tracking your generosity"
        )
    }
    .padding()
}
