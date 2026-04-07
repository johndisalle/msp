import SwiftUI

// MARK: - Verse Card Styles

enum VerseCardStyle: String, CaseIterable {
    case classic
    case sunset
    case midnight
    case nature
    case minimal

    var label: String {
        switch self {
        case .classic: return "Classic"
        case .sunset: return "Sunset"
        case .midnight: return "Midnight"
        case .nature: return "Nature"
        case .minimal: return "Minimal"
        }
    }

    var background: AnyView {
        switch self {
        case .classic:
            return AnyView(
                LinearGradient(
                    colors: [
                        Color(red: 0.43, green: 0.56, blue: 0.52),
                        Color(red: 0.31, green: 0.43, blue: 0.40)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .sunset:
            return AnyView(
                LinearGradient(
                    colors: [
                        Color(red: 0.90, green: 0.55, blue: 0.35),
                        Color(red: 0.80, green: 0.30, blue: 0.40),
                        Color(red: 0.50, green: 0.20, blue: 0.50)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .midnight:
            return AnyView(
                LinearGradient(
                    colors: [
                        Color(red: 0.10, green: 0.12, blue: 0.25),
                        Color(red: 0.18, green: 0.20, blue: 0.38),
                        Color(red: 0.08, green: 0.08, blue: 0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        case .nature:
            return AnyView(
                LinearGradient(
                    colors: [
                        Color(red: 0.22, green: 0.42, blue: 0.35),
                        Color(red: 0.35, green: 0.55, blue: 0.40),
                        Color(red: 0.18, green: 0.35, blue: 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .minimal:
            return AnyView(
                Color(red: 0.97, green: 0.95, blue: 0.92)
            )
        }
    }

    var textColor: Color {
        self == .minimal ? Color(red: 0.17, green: 0.19, blue: 0.25) : .white
    }

    var secondaryTextColor: Color {
        self == .minimal ? Color(red: 0.44, green: 0.47, blue: 0.53) : .white.opacity(0.75)
    }

    var accentColor: Color {
        switch self {
        case .classic: return Color(red: 0.89, green: 0.83, blue: 0.66)
        case .sunset: return Color(red: 1.0, green: 0.85, blue: 0.65)
        case .midnight: return Color(red: 0.65, green: 0.75, blue: 1.0)
        case .nature: return Color(red: 0.75, green: 0.90, blue: 0.70)
        case .minimal: return Color(red: 0.43, green: 0.56, blue: 0.52)
        }
    }
}

// MARK: - Verse Card Editor

struct VerseCardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let reference: String
    let text: String

    @State private var selectedStyle: VerseCardStyle = .classic
    @State private var showShareSheet = false
    @State private var renderedImage: UIImage?
    @State private var isRendering = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Preview
                ScrollView {
                    VerseCardCanvas(
                        reference: reference,
                        text: text,
                        style: selectedStyle
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Style picker
                VStack(spacing: 8) {
                    Text("Choose a Style")
                        .font(.caption)
                        .foregroundStyle(AJTheme.secondaryText)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(VerseCardStyle.allCases, id: \.self) { style in
                                Button {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        selectedStyle = style
                                    }
                                } label: {
                                    VStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .frame(width: 48, height: 48)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(selectedStyle == style ? AJTheme.sage : .clear, lineWidth: 2)
                                            )
                                            .overlay {
                                                style.background.clipShape(RoundedRectangle(cornerRadius: 8))
                                            }

                                        Text(style.label)
                                            .font(.caption2)
                                            .foregroundStyle(selectedStyle == style ? AJTheme.primaryText : AJTheme.secondaryText)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        saveToPhotos()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.caption)
                            Text("Save")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AJTheme.sage.opacity(0.12))
                        .foregroundStyle(AJTheme.sage)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        shareCard()
                    } label: {
                        HStack(spacing: 6) {
                            if isRendering {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.caption)
                            }
                            Text("Share")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AJTheme.sage)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(isRendering)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
            .ajScreenBackground()
            .navigationTitle("Verse Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = renderedImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }

    private func renderCardToImage() -> UIImage? {
        let cardView = VerseCardCanvas(
            reference: reference,
            text: text,
            style: selectedStyle
        )
        .frame(width: 1080, height: 1080)

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 1.0
        return renderer.uiImage
    }

    private func saveToPhotos() {
        guard let image = renderCardToImage() else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func shareCard() {
        isRendering = true
        DispatchQueue.global(qos: .userInitiated).async {
            let cardView = VerseCardCanvas(
                reference: reference,
                text: text,
                style: selectedStyle
            )
            .frame(width: 1080, height: 1080)

            let renderer = ImageRenderer(content: cardView)
            renderer.scale = 1.0
            let image = renderer.uiImage

            DispatchQueue.main.async {
                renderedImage = image
                isRendering = false
                if image != nil {
                    showShareSheet = true
                }
            }
        }
    }
}

// MARK: - Verse Card Canvas (the actual card that gets rendered)

struct VerseCardCanvas: View {
    let reference: String
    let text: String
    let style: VerseCardStyle

    var body: some View {
        ZStack {
            // Background
            style.background

            // Decorative elements
            decorativeOverlay

            // Content
            VStack(spacing: 0) {
                Spacer()

                // Cross / decorative icon
                Image(systemName: "cross.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(style.accentColor.opacity(0.6))
                    .padding(.bottom, 20)

                // Verse text
                Text("\u{201C}\(text)\u{201D}")
                    .font(.system(size: 22, weight: .medium, design: .serif))
                    .italic()
                    .foregroundStyle(style.textColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(8)
                    .padding(.horizontal, 36)

                // Divider
                Rectangle()
                    .fill(style.accentColor.opacity(0.4))
                    .frame(width: 40, height: 2)
                    .padding(.vertical, 20)

                // Reference
                Text(reference)
                    .font(.system(size: 16, weight: .semibold, design: .serif))
                    .foregroundStyle(style.accentColor)

                Spacer()

                // Branding
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10))
                    Text("Abide Journey")
                        .font(.system(size: 11, weight: .medium, design: .serif))
                }
                .foregroundStyle(style.secondaryTextColor)
                .padding(.bottom, 24)
            }
            .padding(24)
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    @ViewBuilder
    private var decorativeOverlay: some View {
        switch style {
        case .midnight:
            // Subtle star dots
            GeometryReader { geo in
                ForEach(0..<15, id: \.self) { i in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.1...0.3)))
                        .frame(width: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat(((i * 73 + 37) % Int(max(geo.size.width, 1)))),
                            y: CGFloat(((i * 47 + 19) % Int(max(geo.size.height, 1))))
                        )
                }
            }
        case .nature:
            // Subtle leaf pattern
            VStack {
                HStack {
                    Spacer()
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.06))
                        .rotationEffect(.degrees(-30))
                }
                Spacer()
                HStack {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.06))
                        .rotationEffect(.degrees(150))
                    Spacer()
                }
            }
        default:
            EmptyView()
        }
    }
}

#Preview {
    VerseCardEditorView(
        reference: "Philippians 4:13",
        text: "I can do all things through Christ who strengthens me."
    )
}
