import SwiftUI
import SwiftData

/// Setup view for starting a couples journey with a partner.
/// Creates a shared journey and sends an invitation via the share sheet.
struct CouplesJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]

    @State private var partnerName = ""
    @State private var selectedTheme: JourneyTheme = .healingRelationships
    @State private var isGenerating = false
    @State private var showingShareSheet = false
    @State private var shareMessage = ""
    @State private var saveError: String?

    private var profile: UserProfile? { profiles.first }

    private let couplesThemes: [(theme: JourneyTheme, couplesTitle: String, couplesSubtitle: String)] = [
        (.healingRelationships, "Healing Our Relationship", "40 days of restoring trust, grace, and connection"),
        (.findingPeace, "Finding Peace Together", "40 days of calm in the storms of life, side by side"),
        (.knowingGod, "Knowing God as a Couple", "40 days discovering God's heart for your relationship"),
        (.spiritualGrowth, "Growing Together in Faith", "40 days deepening your shared walk with God"),
        (.overcomingAnxiety, "Overcoming Worry Together", "40 days of peace when life feels overwhelming"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.pink)

                        Text("Journey Together")
                            .font(.title2.bold())

                        Text("Start a shared 40-day devotional with your partner. Same daily content, couples-focused reflection prompts, and a shared sense of purpose.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Partner name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Partner's Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Name", text: $partnerName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                    }
                    .padding(.horizontal)

                    // Theme selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Your Journey")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(couplesThemes, id: \.theme) { item in
                            Button {
                                selectedTheme = item.theme
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: item.theme.icon)
                                        .font(.title3)
                                        .foregroundStyle(.pink)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(item.couplesTitle)
                                            .font(.subheadline.bold())
                                        Text(item.couplesSubtitle)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    if selectedTheme == item.theme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.pink)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTheme == item.theme ? Color.pink.opacity(0.08) : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTheme == item.theme ? Color.pink : .clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }

                    // How it works
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How It Works")
                            .font(.headline)

                        howItWorksRow(icon: "1.circle.fill", text: "You both get the same daily devotional and scripture")
                        howItWorksRow(icon: "2.circle.fill", text: "Reflection prompts are designed for couples to discuss together")
                        howItWorksRow(icon: "3.circle.fill", text: "Each of you tracks your own progress independently")
                        howItWorksRow(icon: "4.circle.fill", text: "Share encouragement and celebrate milestones together")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray6))
                    )
                    .padding(.horizontal)

                    // Start button
                    Button {
                        startCouplesJourney()
                    } label: {
                        Group {
                            if isGenerating {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "heart.fill")
                                    Text("Start Our Journey")
                                }
                            }
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(partnerName.isEmpty ? Color(.systemGray4) : Color.pink)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(partnerName.isEmpty || isGenerating)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Couples Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [shareMessage])
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

    private func howItWorksRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.pink)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Start Journey

    private func startCouplesJourney() {
        guard let profile else { return }
        isGenerating = true

        // Archive existing active journeys
        for journey in journeys where journey.isActive && !journey.isCompleted {
            journey.isActive = false
            journey.isCompleted = true
        }

        let couplesInfo = couplesThemes.first { $0.theme == selectedTheme }
        let title = couplesInfo?.couplesTitle ?? selectedTheme.rawValue
        let subtitle = couplesInfo?.couplesSubtitle ?? selectedTheme.subtitle

        let newJourney = Journey(
            title: title,
            subtitle: subtitle,
            totalDays: 40,
            theme: selectedTheme,
            focusAreas: Array(DiscipleshipArea.allCases.shuffled().prefix(5))
        )
        newJourney.user = profile
        newJourney.isCouple = true
        newJourney.partnerName = partnerName

        let contentLibrary = ContentLibrary.shared
        let focusAreas = newJourney.focusAreas
        for dayNum in 1...40 {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: selectedTheme, area: focusArea, dayInArea: dayNum)

            let couplesPrompt = couplesReflectionPrompt(original: content.reflectionPrompt, focusArea: focusArea, dayNumber: dayNum)

            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: content.devotionalTitle,
                devotionalText: content.devotionalText,
                reflectionPrompt: couplesPrompt,
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
            saveError = "Failed to create your couples journey. Please try again."
            isGenerating = false
            return
        }

        // Prepare invitation
        let userName = profile.name
        shareMessage = "Hey \(partnerName)! \(userName) wants to do a 40-day faith journey with you called \"\(title)\".\n\n\(subtitle)\n\nDownload Abide Journey so we can walk through this together!"
        isGenerating = false
        showingShareSheet = true

        // Dismiss after sharing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }

    private func couplesReflectionPrompt(original: String, focusArea: DiscipleshipArea, dayNumber: Int) -> String {
        let couplesPrompts: [String] = [
            "Discuss together: \(original) How does this apply to your relationship?",
            "Share with each other: What stood out most to you in today's reading? Why?",
            "Take turns answering: \(original)",
            "Pray together about this: \(original) Then share what God put on your heart.",
            "Write your answers separately, then share: \(original) Where do your reflections overlap?",
            "Ask each other: How can we encourage each other in \(focusArea.rawValue.lowercased()) this week?",
            "Discuss: \(original) How can you support each other in living this out?",
        ]
        return couplesPrompts[(dayNumber - 1) % couplesPrompts.count]
    }
}

#Preview {
    CouplesJourneyView()
        .modelContainer(for: [Journey.self, UserProfile.self], inMemory: true)
}
