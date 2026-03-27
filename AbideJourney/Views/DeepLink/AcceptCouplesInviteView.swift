import SwiftUI
import SwiftData

/// Shown when a user opens a couples journey invitation deep link.
struct AcceptCouplesInviteView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]

    let invite: DeepLinkService.CouplesInvite
    @State private var isGenerating = false
    @State private var saveError: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AJTheme.gold)

                VStack(spacing: 8) {
                    Text("\(invite.fromName) invited you!")
                        .font(AJTheme.headlineFont)

                    Text("to a couples journey")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }

                VStack(spacing: 8) {
                    Image(systemName: invite.theme.icon)
                        .font(.title2)
                        .foregroundStyle(AJTheme.sage)

                    Text(invite.theme.rawValue)
                        .font(AJTheme.subheadlineFont)

                    Text(invite.theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AJTheme.cardBackground)
                )
                .padding(.horizontal)

                Text("You'll both follow the same 40-day devotional with couples-focused reflection prompts.")
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    acceptInvite()
                } label: {
                    Group {
                        if isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            HStack {
                                Image(systemName: "heart.fill")
                                Text("Accept & Start Journey")
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

                Button("Not Now") { dismiss() }
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.secondaryText)
                    .padding(.bottom, 32)
            }
            .ajScreenBackground()
            .navigationTitle("Couples Invitation")
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

    private func acceptInvite() {
        guard let profile else { return }
        isGenerating = true

        // Archive existing active journeys
        for journey in journeys where journey.isActive && !journey.isCompleted {
            journey.isActive = false
            journey.isCompleted = true
        }

        let newJourney = Journey(
            title: invite.theme.rawValue,
            subtitle: invite.theme.subtitle,
            totalDays: 40,
            theme: invite.theme,
            focusAreas: Array(DiscipleshipArea.allCases.shuffled().prefix(5))
        )
        newJourney.user = profile
        newJourney.isCouple = true
        newJourney.partnerName = invite.fromName

        let contentLibrary = ContentLibrary.shared
        let focusAreas = newJourney.focusAreas
        for dayNum in 1...40 {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: invite.theme, area: focusArea, dayInArea: dayNum)

            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: content.devotionalTitle,
                devotionalText: content.devotionalText,
                prayerText: content.prayerText,
                reflectionPrompt: content.reflectionPrompt,
                focusArea: focusArea,
                theme: invite.theme,
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

        Analytics.journeyStarted(theme: invite.theme.rawValue, isCouple: true)
        isGenerating = false
        dismiss()
    }
}
