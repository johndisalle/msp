import SwiftUI

/// Banner that surfaces the Adaptive Journey feature when the current
/// day's content has been adjusted based on the user's recent check-in
/// sentiment. Without this banner, users never realize the app is
/// quietly rewriting their journey for them — an invisible differentiator.
///
/// Shown at the top of Today when `currentDay.hasBeenAdapted == true`
/// and only once per day (tracked in UserDefaults).
struct AdaptationBannerView: View {
    let dayNumber: Int
    @State private var dismissed = false

    private var dismissKey: String { "adaptation_banner_seen_day_\(dayNumber)" }

    private var alreadySeen: Bool {
        UserDefaults.standard.bool(forKey: dismissKey)
    }

    var body: some View {
        if !dismissed && !alreadySeen {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Image(systemName: "sparkles")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.gold)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today was shaped for you")
                            .font(.system(.subheadline, design: .serif, weight: .semibold))
                            .foregroundStyle(AJTheme.primaryText)

                        Text("Based on your recent check-ins, we adjusted today's content to meet you where you are.")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Button {
                        UserDefaults.standard.set(true, forKey: dismissKey)
                        withAnimation(.easeOut(duration: 0.3)) {
                            dismissed = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(6)
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AJTheme.gold.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AJTheme.gold.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
}

#Preview {
    AdaptationBannerView(dayNumber: 5)
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
}
