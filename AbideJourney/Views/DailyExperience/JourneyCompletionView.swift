import SwiftUI
import StoreKit

struct JourneyCompletionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.requestReview) private var requestReview
    let journey: Journey?
    let isPremium: Bool
    let onStartNewJourney: () -> Void

    @State private var animateConfetti = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    Spacer(minLength: 20)

                    // Celebration
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 120, height: 120)
                                .scaleEffect(animateConfetti ? 1.0 : 0.5)
                                .opacity(animateConfetti ? 1.0 : 0)

                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(.green)
                                .symbolEffect(.bounce, value: animateConfetti)
                        }

                        Text("Journey Complete!")
                            .font(.largeTitle.bold())

                        if let journey {
                            Text("You finished all \(journey.totalDays) days of\n\"\(journey.title)\"")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Stats summary
                    if let journey {
                        statsCard(journey: journey)
                    }

                    // Encouragement
                    VStack(spacing: 8) {
                        Text("\"Being confident of this, that He who began a good work in you will carry it on to completion.\"")
                            .font(.body)
                            .italic()
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)

                        Text("— Philippians 1:6")
                            .font(.caption.bold())
                            .foregroundStyle(.accent)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentColor.opacity(0.08))
                    )
                    .padding(.horizontal)

                    // Next journey prompt (premium nudge for free users)
                    if !isPremium {
                        nextJourneyCard
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text(isPremium ? "Done" : "Continue")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    animateConfetti = true
                }
                // Ask for App Store review after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    requestReview()
                }
            }
        }
        .presentationDetents([.large])
    }

    private func statsCard(journey: Journey) -> some View {
        let completedDays = journey.days.filter(\.isCompleted).count
        let journalCount = journey.days.flatMap(\.journalEntries).count
        let totalPrayerMinutes = journey.days
            .flatMap(\.checkIns)
            .reduce(0) { $0 + $1.prayerMinutes }

        return HStack(spacing: 0) {
            completionStat(value: "\(completedDays)", label: "Days\nCompleted", icon: "checkmark.circle.fill", color: .green)
            completionStat(value: "\(journalCount)", label: "Journal\nEntries", icon: "book.fill", color: .purple)
            completionStat(value: "\(totalPrayerMinutes)", label: "Minutes\nin Prayer", icon: "hands.sparkles.fill", color: .blue)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }

    private func completionStat(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var nextJourneyCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)
                Text("Ready for your next journey?")
                    .font(.headline)
            }

            Text("Premium members get unlimited journeys on topics like overcoming anxiety, walking through grief, hearing God's voice, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)

            Button {
                dismiss()
                // Small delay to let dismiss complete before showing paywall
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onStartNewJourney()
                }
            } label: {
                HStack {
                    Text("Upgrade to Premium")
                        .font(.subheadline.bold())
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
    }
}

#Preview {
    JourneyCompletionView(
        journey: nil,
        isPremium: false,
        onStartNewJourney: {}
    )
}
