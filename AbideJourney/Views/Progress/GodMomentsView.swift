import SwiftUI
import PhotosUI

struct GodMomentsView: View {
    @State private var moments: [GodMoment] = []
    @State private var showingCapture = false
    @State private var selectedMoment: GodMoment?

    private let service = GodMomentsService.shared
    private let columns = [GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4), GridItem(.flexible(), spacing: 4)]

    var body: some View {
        Group {
            if moments.isEmpty {
                VStack(spacing: 20) {
                    Spacer()
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 56))
                        .foregroundStyle(AJTheme.sage.opacity(0.4))

                    Text("Capture God Moments")
                        .font(AJTheme.headlineFont)

                    Text("Snap a photo when you see God at work.\nBuild a timeline of His faithfulness.")
                        .font(.subheadline)
                        .foregroundStyle(AJTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)

                    Button {
                        showingCapture = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Capture a Moment")
                        }
                    }
                    .buttonStyle(AJPrimaryButtonStyle())
                    .padding(.horizontal, 60)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Stats
                        HStack {
                            Text("\(moments.count) moment\(moments.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(AJTheme.secondaryText)
                            Spacer()
                            if let first = moments.last {
                                Text("Since \(first.createdAt, format: .dateTime.month().year())")
                                    .font(.caption)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                        }
                        .padding(.horizontal)

                        // Timeline grid
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(moments) { moment in
                                Button {
                                    selectedMoment = moment
                                } label: {
                                    GodMomentThumbnail(moment: moment)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding(.vertical)
                }
            }
        }
        .ajScreenBackground()
        .navigationTitle("God Moments")
        .toolbar {
            if !moments.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCapture = true
                    } label: {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(AJTheme.sage)
                    }
                }
            }
        }
        .onAppear { moments = service.loadMoments() }
        .sheet(isPresented: $showingCapture, onDismiss: {
            moments = service.loadMoments()
        }) {
            GodMomentCaptureSheet()
        }
        .sheet(item: $selectedMoment) { moment in
            GodMomentDetailSheet(moment: moment, onDelete: {
                service.deleteMoment(id: moment.id)
                moments = service.loadMoments()
                selectedMoment = nil
            })
        }
    }
}

// MARK: - Thumbnail

private struct GodMomentThumbnail: View {
    let moment: GodMoment
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.width)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(AJTheme.cream)
                }

                // Caption overlay
                VStack {
                    Spacer()
                    Text(moment.caption)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .padding(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.black.opacity(0.45))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onAppear {
            image = GodMomentsService.shared.loadImage(for: moment)
        }
    }
}

// MARK: - Detail Sheet

private struct GodMomentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let moment: GodMoment
    let onDelete: () -> Void
    @State private var image: UIImage?
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }

                    Text(moment.caption)
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(AJTheme.primaryText)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                        Text(moment.createdAt, format: .dateTime.month().day().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)
                        Spacer()
                    }
                }
                .padding()
            }
            .ajScreenBackground()
            .navigationTitle("God Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        if let image {
                            ShareLink(item: Image(uiImage: image), preview: SharePreview(moment.caption, image: Image(uiImage: image))) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .confirmationDialog("Delete this moment?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                image = GodMomentsService.shared.loadImage(for: moment)
            }
        }
    }
}

// MARK: - Capture Sheet

private struct GodMomentCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var caption = ""
    @State private var isSaving = false
    @FocusState private var captionFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo picker
                    if let selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(alignment: .topTrailing) {
                                Button {
                                    self.selectedImage = nil
                                    self.selectedPhoto = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.white)
                                        .shadow(radius: 4)
                                }
                                .padding(8)
                            }
                    } else {
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 40))
                                    .foregroundStyle(AJTheme.sage)
                                Text("Choose a Photo")
                                    .font(.subheadline.bold())
                                    .foregroundStyle(AJTheme.sage)
                                Text("Capture what God is doing")
                                    .font(.caption)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 200)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(AJTheme.sage.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                                            .foregroundStyle(AJTheme.sage.opacity(0.3))
                                    )
                            )
                        }
                    }

                    // Caption
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What did you see God do?")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        TextField("A small miracle, an answered prayer, a moment of peace...", text: $caption, axis: .vertical)
                            .focused($captionFocused)
                            .lineLimit(3...6)
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

                    // Save
                    Button {
                        saveGodMoment()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Save God Moment")
                        }
                    }
                    .buttonStyle(AJPrimaryButtonStyle())
                    .disabled(selectedImage == nil || caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                    .opacity(selectedImage == nil || caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    .padding(.bottom, 32)
                }
                .padding()
            }
            .ajScreenBackground()
            .navigationTitle("New God Moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        selectedImage = img
                    }
                }
            }
        }
    }

    private func saveGodMoment() {
        guard let image = selectedImage else { return }
        isSaving = true
        let trimmed = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        _ = GodMomentsService.shared.addMoment(caption: trimmed, image: image)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        GodMomentsView()
    }
}
