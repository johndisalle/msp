import SwiftUI
import SwiftData

/// Lets users describe what they're going through and generates a fully
/// personalized 40-day journey based on their situation.
struct DynamicJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]

    @State private var userDescription = ""
    @State private var isGenerating = false
    @State private var saveError: String?
    @FocusState private var isFocused: Bool

    private var profile: UserProfile? { profiles.first }

    private let examples = [
        "I just lost my mom and I don't know how to grieve",
        "I'm starting a new job and feel overwhelmed",
        "My marriage is struggling and I need hope",
        "I've been feeling far from God lately",
        "I want to learn how to pray more consistently",
        "I'm dealing with addiction and need strength",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 44))
                            .foregroundStyle(AJTheme.sage)

                        Text("Create Your Journey")
                            .font(AJTheme.headlineFont)

                        Text("Tell us what you're going through, and we'll build a personalized 40-day journey just for you.")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's on your heart?")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        TextEditor(text: $userDescription)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(AJTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)

                        Text("\(userDescription.count)/500")
                            .font(.caption2)
                            .foregroundStyle(AJTheme.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.horizontal)

                    // Examples
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or tap an example:")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                            .padding(.horizontal)

                        FlowLayout(spacing: 8) {
                            ForEach(examples, id: \.self) { example in
                                Button {
                                    userDescription = example
                                } label: {
                                    Text(example)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AJTheme.cardBackground)
                                        .clipShape(Capsule())
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // What you'll get
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Journey Will Include")
                            .font(AJTheme.subheadlineFont)

                        featureRow(icon: "text.book.closed.fill", text: "40 daily scriptures chosen for your situation", color: .blue)
                        featureRow(icon: "heart.text.square.fill", text: "Devotionals written around your specific needs", color: .orange)
                        featureRow(icon: "pencil.and.outline", text: "Reflection prompts tailored to your experience", color: .purple)
                        featureRow(icon: "checklist", text: "Action steps you can actually take today", color: .green)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                    )
                    .padding(.horizontal)

                    // Generate button
                    Button {
                        generateJourney()
                    } label: {
                        Group {
                            if isGenerating {
                                VStack(spacing: 6) {
                                    ProgressView().tint(.white)
                                    Text("Creating your journey...")
                                        .font(.caption)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "wand.and.stars")
                                    Text("Create My Journey")
                                }
                            }
                        }
                        .font(AJTheme.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(userDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AJTheme.sandstone : AJTheme.sage)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(userDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isGenerating)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .ajScreenBackground()
            .navigationTitle("Custom Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Generation Failed", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .onAppear { isFocused = true }
        }
    }

    private func featureRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
        }
    }

    // MARK: - Journey Generation

    private func generateJourney() {
        guard let profile else { return }
        isGenerating = true

        // Analyze the user's description to pick the best theme and focus areas
        let analysis = analyzeDescription(userDescription)

        // Archive existing active journeys
        for journey in journeys where journey.isActive && !journey.isCompleted {
            journey.isActive = false
            journey.isCompleted = true
        }

        let newJourney = Journey(
            title: analysis.title,
            subtitle: String(userDescription.prefix(80)),
            totalDays: 40,
            theme: analysis.theme,
            focusAreas: analysis.focusAreas
        )
        newJourney.user = profile

        let contentLibrary = ContentLibrary.shared
        let focusAreas = newJourney.focusAreas
        for dayNum in 1...40 {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: analysis.theme, area: focusArea, dayInArea: dayNum)

            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: content.devotionalTitle,
                devotionalText: content.devotionalText,
                prayerText: content.prayerText,
                reflectionPrompt: personalizePrompt(content.reflectionPrompt, context: userDescription),
                focusArea: focusArea,
                theme: analysis.theme,
                actionSteps: content.actionSteps.map { ActionStep(text: $0) }
            )
            day.journey = newJourney
            modelContext.insert(day)
        }

        modelContext.insert(newJourney)
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to create your journey. Please try again."
            isGenerating = false
            return
        }

        Analytics.customJourneyCreated()
        Analytics.journeyStarted(theme: analysis.theme.rawValue, isCouple: false)
        isGenerating = false
        dismiss()
    }

    // MARK: - NLP-lite Analysis

    private struct JourneyAnalysis {
        let title: String
        let theme: JourneyTheme
        let focusAreas: [DiscipleshipArea]
    }

    private func analyzeDescription(_ text: String) -> JourneyAnalysis {
        let lowered = text.lowercased()

        // Theme matching based on keywords
        let theme: JourneyTheme
        let title: String

        if lowered.contains("grief") || lowered.contains("loss") || lowered.contains("died") || lowered.contains("lost") || lowered.contains("death") {
            theme = .walkingThroughGrief
            title = "Walking Through Grief"
        } else if lowered.contains("anxiety") || lowered.contains("anxious") || lowered.contains("worry") || lowered.contains("overwhelm") || lowered.contains("stress") {
            theme = .overcomingAnxiety
            title = "Finding Peace in the Storm"
        } else if lowered.contains("marriage") || lowered.contains("relationship") || lowered.contains("spouse") || lowered.contains("partner") || lowered.contains("divorce") {
            theme = .healingRelationships
            title = "Healing & Hope for Relationships"
        } else if lowered.contains("lead") || lowered.contains("leadership") || lowered.contains("manage") || lowered.contains("boss") || lowered.contains("team") {
            theme = .leadingLikeJesus
            title = "Leading with God's Heart"
        } else if lowered.contains("start over") || lowered.contains("new beginning") || lowered.contains("failed") || lowered.contains("failure") || lowered.contains("addiction") || lowered.contains("recovery") {
            theme = .startingOver
            title = "Grace for a New Beginning"
        } else if lowered.contains("doubt") || lowered.contains("question") || lowered.contains("believe") || lowered.contains("faith") && lowered.contains("struggle") {
            theme = .overcomingDoubt
            title = "Finding Faith in the Questions"
        } else if lowered.contains("pray") || lowered.contains("prayer") || lowered.contains("hear god") || lowered.contains("god's voice") || lowered.contains("silent") {
            theme = .hearingGodsVoice
            title = "Learning to Hear God"
        } else if lowered.contains("peace") || lowered.contains("calm") || lowered.contains("rest") || lowered.contains("still") {
            theme = .findingPeace
            title = "Finding Rest for Your Soul"
        } else if lowered.contains("grow") || lowered.contains("deeper") || lowered.contains("closer to god") || lowered.contains("spiritual") {
            theme = .spiritualGrowth
            title = "Going Deeper with God"
        } else if lowered.contains("share") || lowered.contains("witness") || lowered.contains("evangeli") || lowered.contains("tell") && lowered.contains("about god") {
            theme = .sharingFaith
            title = "Sharing Your Story"
        } else {
            theme = .spiritualGrowth
            title = "A Journey Made for You"
        }

        // Focus areas - prioritize based on detected needs
        var areas = DiscipleshipArea.allCases.shuffled()
        if lowered.contains("pray") { areas = [.prayer] + areas.filter { $0 != .prayer } }
        if lowered.contains("bible") || lowered.contains("scripture") || lowered.contains("word") { areas = [.scripture] + areas.filter { $0 != .scripture } }
        if lowered.contains("communit") || lowered.contains("alone") || lowered.contains("isolat") { areas = [.community] + areas.filter { $0 != .community } }

        return JourneyAnalysis(
            title: title,
            theme: theme,
            focusAreas: Array(areas.prefix(5))
        )
    }

    private func personalizePrompt(_ original: String, context: String) -> String {
        // Prepend contextual framing to the reflection prompt
        let prefix = "Thinking about what you shared — "
        let contextSnippet = String(context.prefix(60)).trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(prefix)\"\(contextSnippet)...\" — \(original)"
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    DynamicJourneyView()
        .modelContainer(for: [Journey.self, UserProfile.self], inMemory: true)
}
