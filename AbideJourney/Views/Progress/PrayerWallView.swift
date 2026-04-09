import SwiftUI

struct PrayerWallView: View {
    enum PrayerTab: String, CaseIterable {
        case myPrayers = "My Prayers"
        case community = "Community"
    }

    @State private var selectedTab: PrayerTab = .myPrayers
    @State private var requests: [PrayerRequest] = []
    @State private var showingNewRequest = false
    @State private var showingAnswered = false
    @State private var selectedFilter: PrayerRequest.PrayerCategory?
    @State private var answerRequestID: UUID?
    @State private var answerNote = ""

    private let service = PrayerWallService.shared
    private var community: CommunityService { CommunityService.shared }

    private var activeRequests: [PrayerRequest] {
        let active = requests.filter { !$0.isAnswered }
        if let filter = selectedFilter {
            return active.filter { $0.category == filter }
        }
        return active
    }

    private var answeredRequests: [PrayerRequest] {
        requests.filter(\.isAnswered)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(PrayerTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            if selectedTab == .myPrayers {
                myPrayersContent
            } else {
                communityPrayersContent
            }
        }
        .ajScreenBackground()
        .navigationTitle("Prayer Wall")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingNewRequest = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(AJTheme.sage)
                }
            }
        }
        .onAppear {
            requests = service.loadRequests()
            Task { await community.loadCommunityPrayers() }
        }
        .sheet(isPresented: $showingNewRequest, onDismiss: {
            requests = service.loadRequests()
        }) {
            NewPrayerRequestSheet()
        }
        .alert("Prayer Answered!", isPresented: Binding(
            get: { answerRequestID != nil },
            set: { if !$0 { answerRequestID = nil } }
        )) {
            TextField("How did God answer? (optional)", text: $answerNote)
            Button("Mark Answered") {
                if let id = answerRequestID {
                    service.markAnswered(id: id, note: answerNote.isEmpty ? nil : answerNote)
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    ReviewPromptService.shared.checkAfterPrayerAnswered()
                    withAnimation { requests = service.loadRequests() }
                }
                answerRequestID = nil
            }
            Button("Cancel", role: .cancel) { answerRequestID = nil }
        } message: {
            Text("How did God answer this prayer?")
        }
    }

    // MARK: - My Prayers Tab

    private var myPrayersContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsHeader
                categoryFilter

                if activeRequests.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(activeRequests) { request in
                            PrayerRequestCard(
                                request: request,
                                onPray: {
                                    service.markPrayed(id: request.id)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    requests = service.loadRequests()
                                },
                                onAnswer: {
                                    answerRequestID = request.id
                                    answerNote = ""
                                },
                                onDelete: {
                                    service.deleteRequest(id: request.id)
                                    withAnimation { requests = service.loadRequests() }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                if !answeredRequests.isEmpty {
                    answeredSection
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Community Prayers Tab

    private var communityPrayersContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Community header
                VStack(spacing: 6) {
                    Image(systemName: "person.3.fill")
                        .font(.title2)
                        .foregroundStyle(AJTheme.sage)
                    Text("Pray with believers around the world")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                }
                .padding(.top, 12)

                if community.isLoadingPrayers {
                    ProgressView("Loading prayers...")
                        .padding(.top, 40)
                } else if community.communityPrayers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "hands.sparkles.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(AJTheme.sage.opacity(0.3))
                        Text("No community prayers yet")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("Be the first to share a prayer request!")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                    }
                    .padding(.vertical, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(community.communityPrayers) { prayer in
                            CommunityPrayerCard(prayer: prayer)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await community.loadCommunityPrayers()
        }
    }

    // MARK: - Stats Header

    private var statsHeader: some View {
        HStack(spacing: 0) {
            PrayerStat(value: "\(service.activeCount)", label: "Active", icon: "flame.fill", color: .orange)
            PrayerStat(value: "\(service.totalPrayers)", label: "Times\nPrayed", icon: "hands.sparkles.fill", color: .blue)
            PrayerStat(value: "\(service.answeredCount)", label: "Answered", icon: "checkmark.seal.fill", color: .green)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .padding(.horizontal)
    }

    // MARK: - Category Filter

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(PrayerRequest.PrayerCategory.allCases, id: \.self) { cat in
                    FilterChip(
                        label: cat.rawValue,
                        icon: cat.icon,
                        isSelected: selectedFilter == cat
                    ) {
                        selectedFilter = selectedFilter == cat ? nil : cat
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "hands.sparkles.fill")
                .font(.system(size: 48))
                .foregroundStyle(AJTheme.sage.opacity(0.4))
            Text("No prayer requests yet")
                .font(AJTheme.subheadlineFont)
            Text("Tap + to add your first prayer request.\nCast your cares on Him.")
                .font(.subheadline)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)

            Button {
                showingNewRequest = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Prayer Request")
                }
            }
            .buttonStyle(AJPrimaryButtonStyle())
            .padding(.horizontal, 60)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Answered Section

    private var answeredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation { showingAnswered.toggle() }
            } label: {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                    Text("Answered Prayers (\(answeredRequests.count))")
                        .font(AJTheme.subheadlineFont)
                        .foregroundStyle(AJTheme.primaryText)
                    Spacer()
                    Image(systemName: showingAnswered ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
            }

            if showingAnswered {
                LazyVStack(spacing: 10) {
                    ForEach(answeredRequests) { request in
                        AnsweredPrayerCard(request: request)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Prayer Request Card

private struct PrayerRequestCard: View {
    let request: PrayerRequest
    let onPray: () -> Void
    let onAnswer: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: request.category.icon)
                    .font(.caption)
                    .foregroundStyle(request.category.color)
                Text(request.category.rawValue)
                    .font(.caption2.bold())
                    .foregroundStyle(request.category.color)
                Spacer()
                Text(request.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Text(request.text)
                .font(.body)
                .foregroundStyle(AJTheme.primaryText)
                .lineSpacing(3)

            HStack(spacing: 12) {
                // Pray button
                Button(action: onPray) {
                    HStack(spacing: 6) {
                        Image(systemName: "hands.sparkles.fill")
                            .font(.caption)
                        Text("Prayed")
                            .font(.caption.bold())
                        if request.prayedCount > 0 {
                            Text("\(request.prayedCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AJTheme.sage))
                        }
                    }
                    .foregroundStyle(AJTheme.sage)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(AJTheme.sage.opacity(0.1))
                    .clipShape(Capsule())
                }

                // Mark answered
                Button(action: onAnswer) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .font(.caption)
                        Text("Answered")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()

                // Delete
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.5))
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
    }
}

// MARK: - Answered Prayer Card

private struct AnsweredPrayerCard: View {
    let request: PrayerRequest

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title3)
                .foregroundStyle(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(request.text)
                    .font(.subheadline)
                    .foregroundStyle(AJTheme.primaryText)
                    .lineLimit(2)

                if let note = request.answeredNote, !note.isEmpty {
                    Text("\"" + note + "\"")
                        .font(.caption)
                        .foregroundStyle(AJTheme.sage)
                        .italic()
                }

                HStack(spacing: 8) {
                    Text("Prayed \(request.prayedCount)x")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if let answered = request.answeredAt {
                        Text("Answered \(answered, style: .relative) ago")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.green.opacity(0.05))
        )
    }
}

// MARK: - New Prayer Request Sheet

private struct NewPrayerRequestSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var selectedCategory: PrayerRequest.PrayerCategory = .personal
    @State private var shareToCommunity = false
    @State private var authorName = ""
    @State private var isAnonymous = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(AJTheme.sage.opacity(0.12))
                            .frame(width: 80, height: 80)
                        Image(systemName: "hands.sparkles.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(AJTheme.sage)
                    }
                    .padding(.top, 16)

                    Text("What's on your heart?")
                        .font(AJTheme.headlineFont)

                    // Category picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        LazyVGrid(columns: [
                            GridItem(.flexible()), GridItem(.flexible()),
                            GridItem(.flexible()), GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(PrayerRequest.PrayerCategory.allCases, id: \.self) { cat in
                                Button {
                                    selectedCategory = cat
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: cat.icon)
                                            .font(.caption)
                                        Text(cat.rawValue)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedCategory == cat ? cat.color.opacity(0.15) : AJTheme.cardBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedCategory == cat ? cat.color : .clear, lineWidth: 1.5)
                                    )
                                    .foregroundStyle(selectedCategory == cat ? cat.color : AJTheme.secondaryText)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Text input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Prayer Request")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        TextEditor(text: $text)
                            .focused($focused)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AJTheme.cardBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AJTheme.sage.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal)

                    // Scripture encouragement
                    VStack(spacing: 6) {
                        Text("\"Cast all your anxiety on him because he cares for you.\"")
                            .font(.caption.italic())
                            .foregroundStyle(AJTheme.secondaryText)
                        Text("— 1 Peter 5:7")
                            .font(.caption2.bold())
                            .foregroundStyle(AJTheme.sage)
                    }
                    .padding(.top, 4)

                    // Share to community toggle
                    Toggle(isOn: $shareToCommunity) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.3.fill")
                                .font(.caption)
                                .foregroundStyle(AJTheme.sage)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Share with Community")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AJTheme.primaryText)
                                Text("Let others pray with you")
                                    .font(.caption)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                        }
                    }
                    .tint(AJTheme.sage)
                    .padding(.horizontal)

                    if shareToCommunity {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Display Name")
                                .font(.caption)
                                .foregroundStyle(AJTheme.secondaryText)
                            TextField("Your first name (or 'Anonymous')", text: $authorName)
                                .textFieldStyle(.roundedBorder)
                        }
                        .padding(.horizontal)

                        Toggle(isOn: $isAnonymous) {
                            Text("Post anonymously")
                                .font(.subheadline)
                                .foregroundStyle(AJTheme.secondaryText)
                        }
                        .tint(AJTheme.sage)
                        .padding(.horizontal)
                    }

                    // Submit
                    Button {
                        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        PrayerWallService.shared.addRequest(text: trimmed, category: selectedCategory)

                        if shareToCommunity {
                            let name = authorName.trimmingCharacters(in: .whitespaces)
                            Task {
                                await CommunityService.shared.submitCommunityPrayer(
                                    text: trimmed,
                                    category: selectedCategory.rawValue,
                                    authorName: name.isEmpty ? "A Fellow Believer" : name,
                                    isAnonymous: isAnonymous
                                )
                            }
                        }

                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "hands.sparkles.fill")
                            Text(shareToCommunity ? "Add & Share Prayer" : "Add to Prayer Wall")
                        }
                    }
                    .buttonStyle(AJPrimaryButtonStyle())
                    .padding(.horizontal)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    .padding(.bottom, 32)
                }
            }
            .ajScreenBackground()
            .navigationTitle("New Prayer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }
}

// MARK: - Supporting Views

private struct PrayerStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(AJTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(label)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? AJTheme.sage : AJTheme.cardBackground)
            .foregroundStyle(isSelected ? .white : AJTheme.secondaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isSelected ? .clear : AJTheme.sage.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Community Prayer Card

private struct CommunityPrayerCard: View {
    let prayer: CommunityPrayer
    private var community: CommunityService { CommunityService.shared }
    @State private var showingReportSheet = false
    @State private var showingBlockConfirmation = false
    @State private var showingReportConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundStyle(AJTheme.sage)
                Text(prayer.isAnonymous ? "Anonymous" : prayer.authorName)
                    .font(.caption2.bold())
                    .foregroundStyle(AJTheme.sage)

                Text("\u{00B7}")
                    .foregroundStyle(.tertiary)
                Text(prayer.category)
                    .font(.caption2)
                    .foregroundStyle(AJTheme.secondaryText)

                Spacer()

                Text(prayer.relativeDate)
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

            Text(prayer.text)
                .font(.body)
                .foregroundStyle(AJTheme.primaryText)
                .lineSpacing(3)

            HStack(spacing: 12) {
                Button {
                    Task { await community.prayForRequest(id: prayer.id) }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: community.hasPrayedForPrayer(prayer.id) ? "hands.sparkles.fill" : "hands.sparkles")
                            .font(.caption)
                        Text(community.hasPrayedForPrayer(prayer.id) ? "Prayed" : "Pray")
                            .font(.caption.bold())
                        if prayer.prayerCount > 0 {
                            Text("\(prayer.prayerCount)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(AJTheme.sage))
                        }
                    }
                    .foregroundStyle(community.hasPrayedForPrayer(prayer.id) ? AJTheme.sage : AJTheme.secondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(community.hasPrayedForPrayer(prayer.id) ? AJTheme.sage.opacity(0.15) : AJTheme.sage.opacity(0.05))
                    .clipShape(Capsule())
                }
                .disabled(community.hasPrayedForPrayer(prayer.id))

                Spacer()

                if prayer.isAnswered {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                        Text("Answered")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.green)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AJTheme.cardBackground)
                .shadow(color: AJTheme.cardShadow, radius: AJTheme.cardShadowRadius, x: 0, y: 2)
        )
        .confirmationDialog("Report this prayer?", isPresented: $showingReportSheet, titleVisibility: .visible) {
            Button("Inappropriate Content", role: .destructive) {
                Task { _ = await community.reportPrayer(id: prayer.id, reason: "inappropriate"); showingReportConfirmation = true }
            }
            Button("Spam", role: .destructive) {
                Task { _ = await community.reportPrayer(id: prayer.id, reason: "spam"); showingReportConfirmation = true }
            }
            Button("Harmful or Abusive", role: .destructive) {
                Task { _ = await community.reportPrayer(id: prayer.id, reason: "abusive"); showingReportConfirmation = true }
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
                community.blockUser(authorId: prayer.authorId)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will no longer see content from this user. This cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        PrayerWallView()
    }
}
