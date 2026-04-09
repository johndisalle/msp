import SwiftUI

// MARK: - Testimony Wall View

struct TestimonyWallView: View {
    enum TestimonyTab: String, CaseIterable {
        case local = "My Stories"
        case community = "Community"
    }

    @State private var selectedTab: TestimonyTab = .local
    @State private var testimonies: [Testimony] = []
    @State private var selectedCategory: TestimonyCategory?
    @State private var showingSubmitSheet = false
    @State private var selectedTestimony: Testimony?
    @State private var showingShareCard = false

    private var community: CommunityService { CommunityService.shared }

    private var filteredTestimonies: [Testimony] {
        let approved = testimonies.filter { $0.isApproved || $0.isFeatured }
        if let cat = selectedCategory {
            return approved.filter { $0.category == cat }
        }
        return approved
    }

    private var pendingCount: Int {
        testimonies.filter { !$0.isApproved && !$0.isFeatured }.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(TestimonyTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            if selectedTab == .local {
                localTestimoniesContent
            } else {
                communityTestimoniesContent
            }
        }
        .ajScreenBackground()
        .navigationTitle("Testimonies")
        .onAppear {
            testimonies = TestimonyService.shared.loadTestimonies()
            Task { await community.loadCommunityTestimonies() }
        }
        .sheet(isPresented: $showingSubmitSheet, onDismiss: {
            testimonies = TestimonyService.shared.loadTestimonies()
        }) {
            SubmitTestimonySheet()
        }
        .sheet(isPresented: $showingShareCard) {
            if let testimony = selectedTestimony {
                TestimonyCardShareView(testimony: testimony)
            }
        }
    }

    // MARK: - Local Testimonies Tab

    private var localTestimoniesContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(AJTheme.gold.opacity(0.12))
                            .frame(width: 72, height: 72)
                        Image(systemName: "text.quote")
                            .font(.system(size: 32))
                            .foregroundStyle(AJTheme.gold)
                    }

                    Text("Testimony Wall")
                        .font(AJTheme.headlineFont)

                    Text("Real stories from real people.\nGod is still in the business of changing lives.")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                .padding(.top, 8)

                // Submit CTA
                Button {
                    showingSubmitSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Your Story")
                                .font(.subheadline.bold())
                            Text("Encourage others with what God has done")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [AJTheme.sage, AJTheme.sage.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                if pendingCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.caption2)
                        Text("You have \(pendingCount) testimon\(pendingCount == 1 ? "y" : "ies") pending review")
                            .font(.caption)
                    }
                    .foregroundStyle(AJTheme.gold)
                    .padding(.horizontal)
                }

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(name: "All", icon: "sparkles", color: AJTheme.sage, isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(TestimonyCategory.allCases, id: \.self) { cat in
                            CategoryChip(name: cat.rawValue.components(separatedBy: " & ").first ?? cat.rawValue, icon: cat.icon, color: cat.color, isSelected: selectedCategory == cat) {
                                selectedCategory = (selectedCategory == cat) ? nil : cat
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Testimonies
                if filteredTestimonies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("No testimonies in this category yet")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("Be the first to share your story!")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredTestimonies) { testimony in
                            TestimonyCard(testimony: testimony, onShare: {
                                selectedTestimony = testimony
                                showingShareCard = true
                            })
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Community Testimonies Tab

    private var communityTestimoniesContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundStyle(AJTheme.gold)
                    Text("Stories from believers everywhere")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                .padding(.top, 12)

                // Submit CTA for community
                Button {
                    showingSubmitSheet = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Your Story")
                                .font(.subheadline.bold())
                            Text("Encourage believers around the world")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [AJTheme.gold, AJTheme.gold.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal)

                if community.isLoadingTestimonies {
                    ProgressView("Loading testimonies...")
                        .padding(.top, 40)
                } else if community.communityTestimonies.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 40))
                            .foregroundStyle(.gray.opacity(0.3))
                        Text("No community testimonies yet")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("Be the first to share your story!")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(community.communityTestimonies) { testimony in
                            CommunityTestimonyCard(testimony: testimony)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await community.loadCommunityTestimonies()
        }
    }
}

// MARK: - Category Chip

private struct CategoryChip: View {
    let name: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(name)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.08))
            .foregroundStyle(isSelected ? color : AJTheme.secondaryText)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Testimony Card

struct TestimonyCard: View {
    let testimony: Testimony
    let onShare: () -> Void
    @State private var hasPrayed: Bool = false
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(testimony.category.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: testimony.category.icon)
                        .font(.body)
                        .foregroundStyle(testimony.category.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(testimony.authorName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)
                    HStack(spacing: 4) {
                        Text(testimony.journeyTheme)
                            .font(.caption2)
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("\u{00B7}")
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("\(testimony.dayCount) days")
                            .font(.caption2)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                }

                Spacer()

                if testimony.isFeatured {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            // Title
            Text(testimony.title)
                .font(.headline)
                .foregroundStyle(AJTheme.primaryText)

            // Story
            Text(testimony.story)
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .lineSpacing(4)
                .lineLimit(expanded ? nil : 4)

            if testimony.story.count > 200 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expanded.toggle()
                    }
                } label: {
                    Text(expanded ? "Read Less" : "Read More")
                        .font(.caption.bold())
                        .foregroundStyle(testimony.category.color)
                }
            }

            Divider()

            // Actions
            HStack(spacing: 20) {
                Button {
                    if !hasPrayed {
                        hasPrayed = true
                        TestimonyService.shared.prayForTestimony(id: testimony.id)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: hasPrayed ? "hands.sparkles.fill" : "hands.sparkles")
                            .font(.caption)
                        Text(hasPrayed ? "Prayed" : "Pray")
                            .font(.caption.bold())
                        if testimony.prayerCount > 0 || hasPrayed {
                            Text("\(testimony.prayerCount + (hasPrayed ? 1 : 0))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(hasPrayed ? AJTheme.sage : AJTheme.secondaryText)
                }

                Button(action: onShare) {
                    HStack(spacing: 5) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                        Text("Share")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(AJTheme.secondaryText)
                }

                Spacer()

                Text(testimony.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(testimony.category.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(testimony.category.color.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .onAppear {
            hasPrayed = TestimonyService.shared.hasPrayed(for: testimony.id)
        }
    }
}

// MARK: - Submit Testimony Sheet

struct SubmitTestimonySheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var authorName = ""
    @State private var title = ""
    @State private var story = ""
    @State private var selectedCategory: TestimonyCategory = .faith
    @State private var journeyTheme = ""
    @State private var dayCount = 40
    @State private var submitted = false
    @State private var shareToCommunity = true

    var body: some View {
        NavigationStack {
            if submitted {
                submittedView
            } else {
                formView
            }
        }
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 36))
                        .foregroundStyle(AJTheme.gold)
                    Text("Share Your Testimony")
                        .font(AJTheme.headlineFont)
                    Text("Your story could be the reason someone doesn't give up today.")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 12)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your First Name & Last Initial")
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                    TextField("e.g. Sarah M.", text: $authorName)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Category
                VStack(alignment: .leading, spacing: 10) {
                    Text("What area did God work in?")
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                        .padding(.horizontal)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(TestimonyCategory.allCases, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: cat.icon)
                                        .font(.caption)
                                    Text(cat.rawValue.components(separatedBy: " & ").first ?? cat.rawValue)
                                        .font(.caption.bold())
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(selectedCategory == cat ? cat.color.opacity(0.15) : Color.gray.opacity(0.08))
                                )
                                .foregroundStyle(selectedCategory == cat ? cat.color : AJTheme.secondaryText)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedCategory == cat ? cat.color : .clear, lineWidth: 1.5)
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Give your testimony a title")
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)
                    TextField("e.g. From Panic Attacks to Peace", text: $title)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)

                // Story
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Your story")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                        Spacer()
                        Text("\(story.count)/2000")
                            .font(.caption2)
                            .foregroundStyle(story.count > 2000 ? .red : AJTheme.secondaryText)
                    }
                    TextEditor(text: $story)
                        .frame(minHeight: 180)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding(.horizontal)

                // Share to community toggle
                Toggle(isOn: $shareToCommunity) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.3.fill")
                            .font(.caption)
                            .foregroundStyle(AJTheme.gold)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share with Community")
                                .font(.subheadline.bold())
                                .foregroundStyle(AJTheme.primaryText)
                            Text("Encourage believers around the world")
                                .font(.caption)
                                .foregroundStyle(AJTheme.secondaryText)
                        }
                    }
                }
                .tint(AJTheme.gold)
                .padding(.horizontal)

                // Guidelines
                VStack(alignment: .leading, spacing: 8) {
                    Text("Guidelines")
                        .font(.caption.bold())
                        .foregroundStyle(AJTheme.secondaryText)
                    guidelineRow(icon: "checkmark.circle.fill", text: "Share how God worked in your life", color: .green)
                    guidelineRow(icon: "checkmark.circle.fill", text: "Be honest and authentic", color: .green)
                    guidelineRow(icon: "checkmark.circle.fill", text: "Keep it encouraging for others", color: .green)
                    guidelineRow(icon: "info.circle.fill", text: "All testimonies are reviewed before publishing", color: .blue)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.06))
                )
                .padding(.horizontal)

                // Submit
                Button {
                    submitTestimony()
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Submit Testimony")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSubmit ? AJTheme.sage : AJTheme.sandstone)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!canSubmit)
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
        .ajScreenBackground()
        .navigationTitle("Submit Testimony")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var submittedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AJTheme.sage.opacity(0.15))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AJTheme.sage)
            }

            Text("Testimony Submitted!")
                .font(.title2.bold())
                .foregroundStyle(AJTheme.primaryText)

            Text("Thank you for sharing your story, \(authorName). Your testimony will be reviewed and published to encourage others in their faith journey.")
                .font(.body)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            VStack(spacing: 4) {
                Text("\"They triumphed over him by the blood")
                    .font(.subheadline.italic())
                Text("of the Lamb and by the word of their testimony.\"")
                    .font(.subheadline.italic())
                Text("Revelation 12:11")
                    .font(.caption.bold())
                    .foregroundStyle(AJTheme.gold)
                    .padding(.top, 4)
            }
            .foregroundStyle(AJTheme.secondaryText)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AJTheme.sage)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .ajScreenBackground()
    }

    private var canSubmit: Bool {
        !authorName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        story.count >= 50 && story.count <= 2000
    }

    private func submitTestimony() {
        let trimmedName = authorName.trimmingCharacters(in: .whitespaces)
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedStory = story.trimmingCharacters(in: .whitespaces)
        let theme = journeyTheme.isEmpty ? selectedCategory.rawValue : journeyTheme

        let testimony = Testimony(
            authorName: trimmedName,
            journeyTheme: theme,
            category: selectedCategory,
            title: trimmedTitle,
            story: trimmedStory,
            dayCount: dayCount
        )
        TestimonyService.shared.submitTestimony(testimony)

        if shareToCommunity {
            Task {
                await CommunityService.shared.submitCommunityTestimony(
                    title: trimmedTitle,
                    story: trimmedStory,
                    category: selectedCategory.rawValue,
                    authorName: trimmedName,
                    journeyTheme: theme,
                    dayCount: dayCount
                )
            }
        }

        withAnimation { submitted = true }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func guidelineRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            Text(text)
                .font(.caption)
                .foregroundStyle(AJTheme.secondaryText)
        }
    }
}

// MARK: - Shareable Testimony Card

struct TestimonyCardShareView: View {
    @Environment(\.dismiss) private var dismiss
    let testimony: Testimony
    @State private var selectedStyle: TestimonyCardStyle = .classic

    enum TestimonyCardStyle: String, CaseIterable {
        case classic, warm, ocean, midnight

        var background: [Color] {
            switch self {
            case .classic: return [Color(red: 0.43, green: 0.56, blue: 0.52), Color(red: 0.31, green: 0.43, blue: 0.40)]
            case .warm: return [Color(red: 0.85, green: 0.65, blue: 0.40), Color(red: 0.70, green: 0.40, blue: 0.35)]
            case .ocean: return [Color(red: 0.20, green: 0.50, blue: 0.65), Color(red: 0.15, green: 0.35, blue: 0.55)]
            case .midnight: return [Color(red: 0.15, green: 0.15, blue: 0.30), Color(red: 0.08, green: 0.08, blue: 0.20)]
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                TestimonyShareCanvas(testimony: testimony, style: selectedStyle)
                    .frame(width: 340, height: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 10)

                // Style picker
                HStack(spacing: 12) {
                    ForEach(TestimonyCardStyle.allCases, id: \.self) { style in
                        Button {
                            selectedStyle = style
                        } label: {
                            Circle()
                                .fill(LinearGradient(colors: style.background, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle().stroke(.white, lineWidth: selectedStyle == style ? 3 : 0)
                                )
                                .shadow(radius: 2)
                        }
                    }
                }

                HStack(spacing: 16) {
                    Button {
                        saveToPhotos()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save")
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AJTheme.sage)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        shareCard()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share")
                        }
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AJTheme.gold)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .ajScreenBackground()
            .navigationTitle("Share Testimony")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    @MainActor
    private func renderImage() -> UIImage? {
        let renderer = ImageRenderer(content:
            TestimonyShareCanvas(testimony: testimony, style: selectedStyle)
                .frame(width: 1080, height: 1080)
        )
        renderer.scale = 1.0
        return renderer.uiImage
    }

    private func saveToPhotos() {
        guard let image = renderImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func shareCard() {
        guard let image = renderImage() else { return }
        let av = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.keyWindow?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

// MARK: - Testimony Share Canvas

struct TestimonyShareCanvas: View {
    let testimony: Testimony
    let style: TestimonyCardShareView.TestimonyCardStyle

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: style.background, startPoint: .topLeading, endPoint: .bottomTrailing)

                VStack(spacing: 0) {
                    Spacer()

                    // Quote icon
                    Image(systemName: "quote.opening")
                        .font(.system(size: geo.size.width * 0.08))
                        .foregroundStyle(.white.opacity(0.3))

                    Spacer().frame(height: geo.size.width * 0.04)

                    // Title
                    Text(testimony.title)
                        .font(.system(size: geo.size.width * 0.06, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, geo.size.width * 0.1)

                    Spacer().frame(height: geo.size.width * 0.04)

                    // Story excerpt
                    Text(String(testimony.story.prefix(200)) + (testimony.story.count > 200 ? "..." : ""))
                        .font(.system(size: geo.size.width * 0.035))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, geo.size.width * 0.1)

                    Spacer().frame(height: geo.size.width * 0.06)

                    // Author
                    Text("- \(testimony.authorName)")
                        .font(.system(size: geo.size.width * 0.04, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))

                    Text(testimony.journeyTheme)
                        .font(.system(size: geo.size.width * 0.03))
                        .foregroundStyle(.white.opacity(0.5))

                    Spacer()

                    // App branding
                    HStack(spacing: 6) {
                        Image(systemName: "cross.circle.fill")
                            .font(.system(size: geo.size.width * 0.035))
                        Text("Abide Journey")
                            .font(.system(size: geo.size.width * 0.03, weight: .medium))
                    }
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, geo.size.width * 0.06)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Community Testimony Card

private struct CommunityTestimonyCard: View {
    let testimony: CommunityTestimony
    @State private var expanded = false
    @State private var showingReportSheet = false
    @State private var showingBlockConfirmation = false
    @State private var showingReportConfirmation = false
    private var community: CommunityService { CommunityService.shared }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(AJTheme.gold.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.circle.fill")
                        .font(.body)
                        .foregroundStyle(AJTheme.gold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(testimony.authorName)
                        .font(.subheadline.bold())
                        .foregroundStyle(AJTheme.primaryText)
                    HStack(spacing: 4) {
                        if let theme = testimony.journeyTheme, !theme.isEmpty {
                            Text(theme)
                                .font(.caption2)
                                .foregroundStyle(AJTheme.secondaryText)
                            Text("\u{00B7}")
                                .foregroundStyle(AJTheme.secondaryText)
                        }
                        if let days = testimony.dayCount {
                            Text("\(days) days")
                                .font(.caption2)
                                .foregroundStyle(AJTheme.secondaryText)
                        }
                    }
                }

                Spacer()

                if testimony.isFeatured {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }

                Text(testimony.relativeDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                Menu {
                    Button(role: .destructive) {
                        showingReportSheet = true
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                    Button(role: .destructive) {
                        showingBlockConfirmation = true
                    } label: {
                        Label("Block User", systemImage: "hand.raised")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 4)
                }
            }

            // Title
            Text(testimony.title)
                .font(.headline)
                .foregroundStyle(AJTheme.primaryText)

            // Story
            Text(testimony.story)
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .lineSpacing(4)
                .lineLimit(expanded ? nil : 4)

            if testimony.story.count > 200 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        expanded.toggle()
                    }
                } label: {
                    Text(expanded ? "Read Less" : "Read More")
                        .font(.caption.bold())
                        .foregroundStyle(AJTheme.gold)
                }
            }

            Divider()

            // Actions
            HStack(spacing: 20) {
                Button {
                    Task { await community.prayForTestimony(id: testimony.id) }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: community.hasPrayedForTestimony(testimony.id) ? "hands.sparkles.fill" : "hands.sparkles")
                            .font(.caption)
                        Text(community.hasPrayedForTestimony(testimony.id) ? "Prayed" : "Pray")
                            .font(.caption.bold())
                        if testimony.prayerCount > 0 {
                            Text("\(testimony.prayerCount)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(community.hasPrayedForTestimony(testimony.id) ? AJTheme.sage : AJTheme.secondaryText)
                }
                .disabled(community.hasPrayedForTestimony(testimony.id))

                Spacer()

                Text(testimony.category)
                    .font(.caption2)
                    .foregroundStyle(AJTheme.gold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(AJTheme.gold.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .confirmationDialog("Report this testimony?", isPresented: $showingReportSheet, titleVisibility: .visible) {
            Button("Inappropriate Content", role: .destructive) {
                Task { await community.reportTestimony(id: testimony.id, reason: "inappropriate"); showingReportConfirmation = true }
            }
            Button("Spam", role: .destructive) {
                Task { await community.reportTestimony(id: testimony.id, reason: "spam"); showingReportConfirmation = true }
            }
            Button("Harmful or Abusive", role: .destructive) {
                Task { await community.reportTestimony(id: testimony.id, reason: "abusive"); showingReportConfirmation = true }
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Report Submitted", isPresented: $showingReportConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you. Our team will review this content.")
        }
        .confirmationDialog("Block this user?", isPresented: $showingBlockConfirmation, titleVisibility: .visible) {
            Button("Block User", role: .destructive) {
                community.blockUser(authorId: testimony.authorId)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will no longer see content from this user. This cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        TestimonyWallView()
    }
}
