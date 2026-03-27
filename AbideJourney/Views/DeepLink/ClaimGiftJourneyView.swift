import SwiftUI
import SwiftData

/// Shown when a user opens a gift journey deep link.
struct ClaimGiftJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]

    let gift: DeepLinkService.GiftClaim
    @State private var isGenerating = false
    @State private var saveError: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "gift.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AJTheme.gold)

                VStack(spacing: 8) {
                    Text("A Gift from \(gift.fromName)")
                        .font(AJTheme.headlineFont)

                    if let message = gift.message, !message.isEmpty {
                        Text("\"\(message)\"")
                            .font(.subheadline.italic())
                            .foregroundStyle(AJTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }

                VStack(spacing: 8) {
                    Image(systemName: gift.theme.icon)
                        .font(.title2)
                        .foregroundStyle(AJTheme.sage)

                    Text(gift.theme.rawValue)
                        .font(AJTheme.subheadlineFont)

                    Text(gift.theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)

                    Text("40-Day Premium Journey")
                        .font(.caption2)
                        .foregroundStyle(AJTheme.gold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(AJTheme.gold.opacity(0.12))
                        .clipShape(Capsule())
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AJTheme.sage.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                .foregroundStyle(AJTheme.sage.opacity(0.3))
                        )
                )
                .padding(.horizontal)

                Spacer()

                Button {
                    claimGift()
                } label: {
                    Group {
                        if isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            HStack {
                                Image(systemName: "gift.fill")
                                Text("Start My Gift Journey")
                            }
                        }
                    }
                    .font(AJTheme.subheadlineFont)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AJTheme.sage)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(isGenerating)
                .padding(.horizontal)

                Button("Maybe Later") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.secondaryText)
                    .padding(.bottom, 32)
            }
            .ajScreenBackground()
            .navigationTitle("Gift Journey")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Save Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private func claimGift() {
        guard let profile else { return }
        isGenerating = true

        // Archive existing active journeys
        for journey in journeys where journey.isActive && !journey.isCompleted {
            journey.isActive = false
            journey.isCompleted = true
        }

        let newJourney = Journey(
            title: gift.theme.rawValue,
            subtitle: "A gift from \(gift.fromName)",
            totalDays: 40,
            theme: gift.theme,
            focusAreas: Array(DiscipleshipArea.allCases.shuffled().prefix(5))
        )
        newJourney.user = profile

        let contentLibrary = ContentLibrary.shared
        let focusAreas = newJourney.focusAreas
        for dayNum in 1...40 {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: gift.theme, area: focusArea, dayInArea: dayNum)

            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: content.devotionalTitle,
                devotionalText: content.devotionalText,
                prayerText: content.prayerText,
                reflectionPrompt: content.reflectionPrompt,
                focusArea: focusArea,
                theme: gift.theme,
                actionSteps: content.actionSteps.map { ActionStep(text: $0) }
            )
            day.journey = newJourney
            modelContext.insert(day)
        }

        modelContext.insert(newJourney)
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to start the journey. Please try again."
            isGenerating = false
            return
        }

        Analytics.journeyStarted(theme: gift.theme.rawValue, isCouple: false)
        isGenerating = false
        dismiss()
    }
}
