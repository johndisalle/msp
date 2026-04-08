import SwiftUI
import SwiftData

struct FamilyJourneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var profiles: [UserProfile]
    @Query private var journeys: [Journey]

    @State private var familyMembers: [FamilyMember] = []
    @State private var newMemberName = ""
    @State private var newMemberAge: AgeGroup = .child
    @State private var selectedTheme: FamilyTheme = .faithFoundations
    @State private var isGenerating = false
    @State private var showingShareSheet = false
    @State private var shareMessage = ""
    @State private var saveError: String?

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AJTheme.gold.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Image(systemName: "figure.2.and.child.holdinghands")
                                .font(.system(size: 36))
                                .foregroundStyle(AJTheme.gold)
                        }

                        Text("Family Journey")
                            .font(AJTheme.headlineFont)

                        Text("Grow in faith as a family with age-appropriate devotionals, fun discussions, and shared prayer time.")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)

                    // Family Members
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Who's Joining?")
                            .font(AJTheme.subheadlineFont)
                            .padding(.horizontal)

                        // Added members
                        ForEach(familyMembers) { member in
                            HStack(spacing: 12) {
                                Image(systemName: member.age.icon)
                                    .font(.title3)
                                    .foregroundStyle(member.age.color)
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(member.name)
                                        .font(.subheadline.bold())
                                    Text(member.age.label)
                                        .font(.caption)
                                        .foregroundStyle(AJTheme.secondaryText)
                                }

                                Spacer()

                                Button {
                                    familyMembers.removeAll { $0.id == member.id }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(member.age.color.opacity(0.06))
                            )
                            .padding(.horizontal)
                        }

                        // Add member form
                        VStack(spacing: 10) {
                            TextField("Family member's name", text: $newMemberName)
                                .textFieldStyle(.roundedBorder)

                            HStack(spacing: 8) {
                                ForEach(AgeGroup.allCases, id: \.self) { age in
                                    Button {
                                        newMemberAge = age
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: age.icon)
                                                .font(.caption)
                                            Text(age.label)
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(newMemberAge == age ? age.color.opacity(0.15) : Color.gray.opacity(0.08))
                                        )
                                        .foregroundStyle(newMemberAge == age ? age.color : AJTheme.secondaryText)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(newMemberAge == age ? age.color : .clear, lineWidth: 1.5)
                                        )
                                    }
                                }
                            }

                            Button {
                                addMember()
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add to Family")
                                }
                                .font(.subheadline.bold())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(newMemberName.isEmpty ? Color.gray.opacity(0.1) : AJTheme.sage.opacity(0.15))
                                .foregroundStyle(newMemberName.isEmpty ? AJTheme.secondaryText : AJTheme.sage)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .disabled(newMemberName.isEmpty)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AJTheme.cardBackground)
                                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    }

                    // Theme Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose Your Family Journey")
                            .font(AJTheme.subheadlineFont)
                            .padding(.horizontal)

                        ForEach(FamilyTheme.allCases, id: \.self) { theme in
                            Button {
                                selectedTheme = theme
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: theme.icon)
                                        .font(.title3)
                                        .foregroundStyle(theme.color)
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(theme.title)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(AJTheme.primaryText)
                                        Text(theme.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(AJTheme.secondaryText)
                                    }

                                    Spacer()

                                    Text("\(theme.days) days")
                                        .font(.caption2)
                                        .foregroundStyle(AJTheme.secondaryText)

                                    if selectedTheme == theme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(theme.color)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTheme == theme ? theme.color.opacity(0.08) : AJTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTheme == theme ? theme.color : .clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }

                    // How it works
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How Family Journeys Work")
                            .font(AJTheme.subheadlineFont)

                        familyFeatureRow(icon: "book.fill", color: .blue, title: "Age-Appropriate Content", text: "Kids get simplified scripture and fun questions. Teens get deeper challenges. Adults get the full devotional.")
                        familyFeatureRow(icon: "bubble.left.and.bubble.right.fill", color: .green, title: "Family Discussion", text: "Each day includes a discussion prompt designed to spark real conversation around the dinner table.")
                        familyFeatureRow(icon: "star.fill", color: .orange, title: "Family Challenges", text: "Fun weekly challenges the whole family does together — acts of kindness, prayer walks, gratitude jars.")
                        familyFeatureRow(icon: "chart.bar.fill", color: .purple, title: "Track Together", text: "Parents can see how the family is progressing through the journey together.")
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AJTheme.cardBackground)
                    )
                    .padding(.horizontal)

                    // Start button
                    Button {
                        startFamilyJourney()
                    } label: {
                        Group {
                            if isGenerating {
                                ProgressView().tint(.white)
                            } else {
                                HStack {
                                    Image(systemName: "figure.2.and.child.holdinghands")
                                    Text("Start Our Family Journey")
                                }
                            }
                        }
                        .font(AJTheme.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(familyMembers.isEmpty ? AJTheme.sandstone : AJTheme.sage)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(familyMembers.isEmpty || isGenerating)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .ajScreenBackground()
            .navigationTitle("Family Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet, onDismiss: {
                dismiss()
            }) {
                ShareSheet(items: [shareMessage])
            }
            .alert("Error", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    // MARK: - Actions

    private func addMember() {
        let member = FamilyMember(name: newMemberName.trimmingCharacters(in: .whitespaces), age: newMemberAge)
        familyMembers.append(member)
        newMemberName = ""
    }

    private func startFamilyJourney() {
        guard let profile else { return }
        isGenerating = true

        // Archive existing active journeys
        for journey in journeys where journey.isActive && !journey.isCompleted {
            journey.isActive = false
            journey.isCompleted = true
        }

        let memberNames = familyMembers.map { $0.name }.joined(separator: ", ")
        let hasKids = familyMembers.contains { $0.age == .child }
        let hasTeens = familyMembers.contains { $0.age == .teen }

        let newJourney = Journey(
            title: selectedTheme.title,
            subtitle: "A family journey with \(memberNames)",
            totalDays: selectedTheme.days,
            theme: selectedTheme.mappedTheme,
            focusAreas: Array(DiscipleshipArea.allCases.shuffled().prefix(5))
        )
        newJourney.user = profile
        newJourney.isCouple = false
        newJourney.partnerName = "Family: \(memberNames)"

        let contentLibrary = ContentLibrary.shared
        let focusAreas = newJourney.focusAreas
        for dayNum in 1...selectedTheme.days {
            let weekNumber = (dayNum - 1) / 7
            let focusArea = focusAreas[weekNumber % focusAreas.count]
            let content = contentLibrary.content(for: selectedTheme.mappedTheme, area: focusArea, dayInArea: dayNum)

            let familyPrompt = familyReflectionPrompt(dayNumber: dayNum, hasKids: hasKids, hasTeens: hasTeens, focusArea: focusArea)
            let kidsSection = hasKids ? "\n\n[For Kids] " + kidsPrompt(dayNumber: dayNum, focusArea: focusArea) : ""
            let teensSection = hasTeens ? "\n\n[For Teens] " + teensPrompt(dayNumber: dayNum, focusArea: focusArea) : ""

            let day = JourneyDay(
                dayNumber: dayNum,
                scriptureReference: content.scriptureReference,
                scriptureText: content.scriptureText,
                devotionalTitle: "Family Devotion: " + content.devotionalTitle,
                devotionalText: content.devotionalText,
                prayerText: familyPrayer(dayNumber: dayNum, memberNames: familyMembers.map { $0.name }),
                reflectionPrompt: familyPrompt + kidsSection + teensSection,
                focusArea: focusArea,
                theme: selectedTheme.mappedTheme,
                actionSteps: familyActionSteps(dayNumber: dayNum, focusArea: focusArea).map { ActionStep(text: $0) }
            )
            day.journey = newJourney
            modelContext.insert(day)
        }

        modelContext.insert(newJourney)
        do {
            try modelContext.save()
        } catch {
            saveError = "Failed to create family journey. Please try again."
            isGenerating = false
            return
        }

        Analytics.journeyStarted(theme: selectedTheme.mappedTheme.rawValue, isCouple: false)

        let userName = profile.name
        shareMessage = "Hey family! \(userName) started a \(selectedTheme.days)-day family faith journey called \"\(selectedTheme.title)\" on Abide Journey.\n\nWe'll have daily devotionals, family discussions, and fun challenges together.\n\nDownload Abide Journey to follow along!"
        isGenerating = false
        showingShareSheet = true
    }

    // MARK: - Content Generators

    private func familyReflectionPrompt(dayNumber: Int, hasKids: Bool, hasTeens: Bool, focusArea: DiscipleshipArea) -> String {
        let prompts = [
            "[Family Discussion] Go around the table: What's one thing from today's reading that surprised you or made you think?",
            "[Family Discussion] If you could ask God one question about today's scripture, what would it be? Share your answers.",
            "[Family Discussion] How can our family live out what we read today? Come up with one thing you can do together this week.",
            "[Family Discussion] Share a time when you saw God at work in your life recently. Everyone takes a turn — no story is too small!",
            "[Family Discussion] What's one thing you're grateful for today? What's one thing you need prayer for? Go around and share both.",
            "[Family Discussion] If you had to explain today's scripture to a friend, how would you say it in your own words?",
            "[Family Discussion] What's the hardest part about following God right now? Be honest — this is a safe space.",
        ]
        return prompts[(dayNumber - 1) % prompts.count]
    }

    private func kidsPrompt(dayNumber: Int, focusArea: DiscipleshipArea) -> String {
        let prompts = [
            "Draw a picture of your favorite part of today's Bible story!",
            "Can you act out today's scripture for your family? Make it fun!",
            "What animal reminds you of how God takes care of us? Why?",
            "If you wrote a letter to God today, what would you say?",
            "What's one nice thing you can do for someone tomorrow? Plan it!",
            "Sing a song about God — make one up or pick your favorite!",
            "Tell everyone: What makes you feel safe? God is even safer than that!",
        ]
        return prompts[(dayNumber - 1) % prompts.count]
    }

    private func teensPrompt(dayNumber: Int, focusArea: DiscipleshipArea) -> String {
        let prompts = [
            "Real talk: What's one thing about faith that's hard for you to believe? It's okay to be honest.",
            "How does today's scripture apply to something you're dealing with at school or with friends?",
            "If your best friend asked why you believe in God, what would you say?",
            "What's one way you can represent your faith this week without being preachy?",
            "Journal for 3 minutes: Write whatever's on your mind and ask God about it.",
            "Find a worship song that matches today's theme. Play it for the family or just listen on your own.",
            "What's one thing you wish adults understood about being a teenager and having faith?",
        ]
        return prompts[(dayNumber - 1) % prompts.count]
    }

    private func familyPrayer(dayNumber: Int, memberNames: [String]) -> String {
        let nameList = memberNames.joined(separator: ", ")
        let prayers = [
            "Lord, thank You for our family — \(nameList). Draw us closer to You and to each other. Help us love like You love. In Jesus' name, Amen.",
            "Father, we come before You as a family. Show each of us something new about Your love today. Protect our hearts and our home. Amen.",
            "God, give \(nameList) the courage to live boldly for You. When the world pulls us one way, anchor us in Your truth. We love You. Amen.",
            "Jesus, thank You for every person at this table. Help us forgive quickly, laugh often, and pray always. Unite our family in faith. Amen.",
            "Holy Spirit, fill our home with Your peace. Where there's stress, bring calm. Where there's doubt, bring faith. Where there's distance, bring closeness. Amen.",
            "Lord, we lift up each member of this family. You know what \(nameList) each need today. Meet us there. We trust You with our family. Amen.",
            "Father, make our family a light in our neighborhood, our school, our workplace. Use us together for Your glory. In Jesus' name, Amen.",
        ]
        return prayers[(dayNumber - 1) % prayers.count]
    }

    private func familyActionSteps(dayNumber: Int, focusArea: DiscipleshipArea) -> [String] {
        let weeklyChallenge: String
        let week = ((dayNumber - 1) / 7) % 6
        switch week {
        case 0: weeklyChallenge = "Family Kindness Week: Do one random act of kindness together each day"
        case 1: weeklyChallenge = "Gratitude Jar: Write one thing you're thankful for and drop it in a jar each day"
        case 2: weeklyChallenge = "Prayer Walk: Take a walk together and pray for your neighbors"
        case 3: weeklyChallenge = "Screen-Free Evening: Spend one evening device-free doing something together"
        case 4: weeklyChallenge = "Serve Together: Find one way to serve your community as a family"
        default: weeklyChallenge = "Memory Verse Week: Memorize this week's scripture together"
        }

        return [
            "Read today's scripture out loud together — take turns reading verses",
            "Have the family discussion at dinner or before bed tonight",
            weeklyChallenge,
        ]
    }

    private func familyFeatureRow(icon: String, color: Color, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(AJTheme.primaryText)
                Text(text)
                    .font(.caption)
                    .foregroundStyle(AJTheme.secondaryText)
                    .lineSpacing(2)
            }
        }
    }
}

// MARK: - Family Member

struct FamilyMember: Identifiable {
    let id = UUID()
    let name: String
    let age: AgeGroup
}

enum AgeGroup: String, CaseIterable {
    case child
    case teen
    case adult

    var label: String {
        switch self {
        case .child: return "Child (5-11)"
        case .teen: return "Teen (12-17)"
        case .adult: return "Adult (18+)"
        }
    }

    var icon: String {
        switch self {
        case .child: return "figure.child"
        case .teen: return "figure.walk"
        case .adult: return "figure.stand"
        }
    }

    var color: Color {
        switch self {
        case .child: return .orange
        case .teen: return .purple
        case .adult: return .blue
        }
    }
}

// MARK: - Family Theme

enum FamilyTheme: CaseIterable {
    case faithFoundations
    case familyPrayer
    case lovingOthers
    case bibleHeroes
    case gratitudeJourney

    var title: String {
        switch self {
        case .faithFoundations: return "Faith Foundations"
        case .familyPrayer: return "Family Prayer Journey"
        case .lovingOthers: return "Loving Others Like Jesus"
        case .bibleHeroes: return "Heroes of the Bible"
        case .gratitudeJourney: return "Gratitude Journey"
        }
    }

    var subtitle: String {
        switch self {
        case .faithFoundations: return "21 days building the basics of faith together"
        case .familyPrayer: return "14 days learning to pray as a family"
        case .lovingOthers: return "21 days of kindness, service, and love"
        case .bibleHeroes: return "28 days exploring courageous Bible characters"
        case .gratitudeJourney: return "14 days of thankfulness and praise"
        }
    }

    var icon: String {
        switch self {
        case .faithFoundations: return "building.columns.fill"
        case .familyPrayer: return "hands.sparkles.fill"
        case .lovingOthers: return "heart.fill"
        case .bibleHeroes: return "shield.fill"
        case .gratitudeJourney: return "sun.max.fill"
        }
    }

    var color: Color {
        switch self {
        case .faithFoundations: return .blue
        case .familyPrayer: return .purple
        case .lovingOthers: return .pink
        case .bibleHeroes: return .orange
        case .gratitudeJourney: return .yellow
        }
    }

    var days: Int {
        switch self {
        case .faithFoundations: return 21
        case .familyPrayer: return 14
        case .lovingOthers: return 21
        case .bibleHeroes: return 28
        case .gratitudeJourney: return 14
        }
    }

    var mappedTheme: JourneyTheme {
        switch self {
        case .faithFoundations: return .knowingGod
        case .familyPrayer: return .findingPeace
        case .lovingOthers: return .bearingFruit
        case .bibleHeroes: return .sharingFaith
        case .gratitudeJourney: return .spiritualGrowth
        }
    }
}

#Preview {
    FamilyJourneyView()
        .modelContainer(for: [Journey.self, UserProfile.self], inMemory: true)
}
