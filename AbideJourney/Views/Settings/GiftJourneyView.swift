import SwiftUI

/// Lets users gift a premium journey to a friend via the system share sheet.
/// Generates a personalized gift message with a shareable link/code.
struct GiftJourneyView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recipientName = ""
    @State private var selectedTheme: JourneyTheme = .overcomingAnxiety
    @State private var personalMessage = ""
    @State private var showingShareSheet = false
    @State private var shareItems: [Any] = []

    private let premiumThemes = JourneyTheme.premiumThemes

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "gift.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AJTheme.gold)

                        Text("Gift a Journey")
                            .font(AJTheme.headlineFont)

                        Text("Give someone you care about a life-changing 40-day journey with God.")
                            .font(.subheadline)
                            .foregroundStyle(AJTheme.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 12)

                    // Recipient
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Who is this for?")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                        TextField("Their name", text: $recipientName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                    }
                    .padding(.horizontal)

                    // Theme selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose a Journey")
                            .font(AJTheme.subheadlineFont)
                            .padding(.horizontal)

                        ForEach(premiumThemes, id: \.self) { theme in
                            Button {
                                selectedTheme = theme
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: theme.icon)
                                        .font(.title3)
                                        .foregroundStyle(Color(theme.color, default: .accentColor))
                                        .frame(width: 32)

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(theme.rawValue)
                                            .font(.subheadline.bold())
                                        Text(theme.subtitle)
                                            .font(.caption)
                                            .foregroundStyle(AJTheme.secondaryText)
                                    }

                                    Spacer()

                                    if selectedTheme == theme {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(AJTheme.sage)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedTheme == theme ? AJTheme.sage.opacity(0.08) : AJTheme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedTheme == theme ? AJTheme.sage : .clear, lineWidth: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal)
                        }
                    }

                    // Personal message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Add a Personal Message (optional)")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                        TextEditor(text: $personalMessage)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(AJTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    // Preview card
                    giftPreviewCard
                        .padding(.horizontal)

                    // Send gift
                    Button {
                        prepareGift()
                    } label: {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Gift")
                        }
                        .font(AJTheme.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(recipientName.isEmpty ? AJTheme.sandstone : AJTheme.sage)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(recipientName.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Gift a Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    // MARK: - Preview Card

    private var giftPreviewCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.title)
                .foregroundStyle(AJTheme.gold)

            Text("A Gift for \(recipientName.isEmpty ? "..." : recipientName)")
                .font(.headline)

            Text(selectedTheme.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !personalMessage.isEmpty {
                Text("\"\(personalMessage)\"")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Text("40-Day Premium Journey")
                .font(.caption2)
                .foregroundStyle(.tertiary)
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
    }

    // MARK: - Gift Logic

    private func prepareGift() {
        var message = "Someone special gifted you a journey with God!\n\n"
        message += "\(selectedTheme.rawValue): \(selectedTheme.subtitle)\n\n"

        if !personalMessage.isEmpty {
            message += "They said: \"\(personalMessage)\"\n\n"
        }

        message += "Download Abide Journey to start your free 40-day \(selectedTheme.rawValue) journey. This gift includes Premium access so you can dive deep.\n\n"
        message += "Download Abide Journey to get started!"

        // Generate shareable image
        let renderer = ImageRenderer(content: giftCardForSharing)
        renderer.scale = 3.0

        if let image = renderer.uiImage {
            shareItems = [image, message]
        } else {
            shareItems = [message]
        }

        showingShareSheet = true
    }

    @MainActor
    private var giftCardForSharing: some View {
        VStack(spacing: 16) {
            Image(systemName: "gift.fill")
                .font(.system(size: 36))
                .foregroundStyle(.blue)

            Text("A Gift for \(recipientName)")
                .font(.title3.bold())

            Text(selectedTheme.rawValue)
                .font(.subheadline)

            Text(selectedTheme.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if !personalMessage.isEmpty {
                Text("\"\(personalMessage)\"")
                    .font(.caption)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }

            Text("Abide Journey")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(32)
        .frame(width: 340)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    GiftJourneyView()
}
