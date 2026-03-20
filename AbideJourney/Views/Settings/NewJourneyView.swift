import SwiftUI
import SwiftData

struct NewJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]

    @State private var selectedTheme: JourneyTheme = .knowingGod
    @State private var isGenerating = false
    @State private var showingPremiumSheet = false
    @State private var saveError: String?

    private var profile: UserProfile? { profiles.first }
    private var isPremium: Bool { profile?.isPremium ?? false }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose your next 40-day theme.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // Free themes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Journeys")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(JourneyTheme.freeThemes, id: \.self) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                isPremiumLocked: false
                            ) {
                                selectedTheme = theme
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Premium themes
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Deep-Dive Journeys")
                                .font(.headline)
                            Image(systemName: "crown.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal)

                        if !isPremium {
                            Text("Unlock these focused journeys with Premium")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal)
                        }

                        ForEach(JourneyTheme.premiumThemes, id: \.self) { theme in
                            ThemeCard(
                                theme: theme,
                                isSelected: selectedTheme == theme,
                                isPremiumLocked: !isPremium
                            ) {
                                if isPremium {
                                    selectedTheme = theme
                                } else {
                                    showingPremiumSheet = true
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Start button
                    Button {
                        startNewJourney()
                    } label: {
                        Group {
                            if isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start \(selectedTheme.rawValue)")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("New Journey")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingPremiumSheet) {
                PremiumPaywallView()
            }
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

    private func startNewJourney() {
        guard let profile else { return }
        isGenerating = true

        // Archive existing active journeys — mark as both inactive and completed
        // so they appear in the Past Journeys list rather than disappearing
        for journey in journeys where journey.isActive && !journey.isCompleted {
            journey.isActive = false
            journey.isCompleted = true
        }

        // Generate new journey with selected theme
        let newJourney = Journey(
            title: selectedTheme.rawValue,
            subtitle: selectedTheme.subtitle,
            totalDays: 40,
            theme: selectedTheme,
            focusAreas: Array(DiscipleshipArea.allCases.shuffled().prefix(5))
        )
        newJourney.user = profile

        let contentLibrary = ContentLibrary.shared
        let focusAreas = newJourney.focusAreas
        for dayNum in 1...40 {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: selectedTheme, area: focusArea, dayInArea: dayNum)
            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: content.devotionalTitle,
                devotionalText: content.devotionalText,
                reflectionPrompt: content.reflectionPrompt,
                focusArea: focusArea,
                theme: selectedTheme,
                actionSteps: content.actionSteps.map { ActionStep(text: $0) }
            )
            day.journey = newJourney
            modelContext.insert(day)
        }

        modelContext.insert(newJourney)
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to save your new journey. Please try again."
            isGenerating = false
            return
        }

        isGenerating = false
        dismiss()
    }
}

// MARK: - Theme Card

private struct ThemeCard: View {
    let theme: JourneyTheme
    let isSelected: Bool
    let isPremiumLocked: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Image(systemName: isPremiumLocked ? "lock.fill" : theme.icon)
                    .font(.title3)
                    .foregroundStyle(isPremiumLocked ? .secondary : Color(theme.color, default: .accentColor))
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 3) {
                    Text(theme.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(isPremiumLocked ? .secondary : .primary)
                    Text(theme.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isPremiumLocked {
                    Text("Premium")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.15))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.accent)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NewJourneyView()
        .modelContainer(for: [Journey.self, UserProfile.self], inMemory: true)
}
