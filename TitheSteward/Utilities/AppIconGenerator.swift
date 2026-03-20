import SwiftUI

/// Use this view in Xcode Previews to capture a 1024x1024 app icon screenshot.
/// Steps: Run preview, right-click → "Copy" or use Xcode's snapshot tools.
struct AppIconPreview: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.831, green: 0.651, blue: 0.200),
                    Color(red: 0.745, green: 0.553, blue: 0.133)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Subtle radial highlight
            RadialGradient(
                colors: [
                    Color.white.opacity(0.2),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 0,
                endRadius: 600
            )

            // Icon symbol
            VStack(spacing: 24) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 400, weight: .regular))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
            }
        }
        .frame(width: 1024, height: 1024)
        .clipShape(RoundedRectangle(cornerRadius: 224, style: .continuous))
    }
}

#Preview("App Icon 1024x1024") {
    AppIconPreview()
        .previewLayout(.fixed(width: 1024, height: 1024))
}
