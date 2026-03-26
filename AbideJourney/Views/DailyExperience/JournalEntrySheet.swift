import SwiftUI

struct JournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var journalText: String
    @Binding var selectedMood: Mood?
    @Binding var isVoiceEntry: Bool
    let prompt: String
    @FocusState private var isFocused: Bool
    @State private var speechService = SpeechRecognitionService()
    @State private var isVoiceMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflection Prompt")
                            .font(AJTheme.captionFont)
                            .foregroundStyle(AJTheme.secondaryText)

                        Text(prompt)
                            .font(AJTheme.scriptureFont)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AJTheme.cream.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Mood selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.caption)
                            .foregroundStyle(AJTheme.secondaryText)

                        HStack(spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button {
                                    selectedMood = mood
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: mood.sfSymbol)
                                            .font(.title2)
                                            .foregroundStyle(mood.color)
                                        Text(mood.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedMood == mood ? AJTheme.sage.opacity(0.15) : .clear)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(mood.label)
                                .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                            }
                        }
                    }

                    // Journal entry with voice toggle
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Your Reflection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                toggleVoiceMode()
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: speechService.isRecording ? "mic.fill" : "mic")
                                        .font(.caption)
                                    Text(speechService.isRecording ? "Listening..." : "Voice")
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(speechService.isRecording ? AJTheme.destructive.opacity(0.15) : AJTheme.sage.opacity(0.1))
                                )
                                .foregroundStyle(speechService.isRecording ? AJTheme.destructive : AJTheme.sage)
                            }
                            .accessibilityLabel(speechService.isRecording ? "Stop recording" : "Start voice entry")
                        }

                        if speechService.isRecording {
                            voiceRecordingIndicator
                        }

                        TextEditor(text: $journalText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(AJTheme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)

                        if let error = speechService.error {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(AJTheme.destructive)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        speechService.stopRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        speechService.stopRecording()
                        dismiss()
                    }
                    .bold()
                }
            }
            .onAppear { isFocused = true }
            .onDisappear { speechService.stopRecording() }
            .onChange(of: speechService.transcribedText) { _, newText in
                if speechService.isRecording, !newText.isEmpty {
                    journalText = newText
                }
            }
        }
        .presentationDetents([.large])
    }

    private var voiceRecordingIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AJTheme.destructive)
                .frame(width: 8, height: 8)

            Text("Speak your reflection — it will appear as text below")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                speechService.stopRecording()
            } label: {
                Text("Stop")
                    .font(.caption.bold())
                    .foregroundStyle(AJTheme.destructive)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AJTheme.destructive.opacity(0.06))
        )
    }

    private func toggleVoiceMode() {
        if speechService.isRecording {
            speechService.stopRecording()
        } else {
            isFocused = false
            Task {
                await speechService.requestAuthorization()
                if speechService.isAuthorized {
                    // Preserve existing text — new speech appends context
                    if !journalText.isEmpty {
                        speechService.transcribedText = journalText
                    }
                    await MainActor.run {
                        speechService.startRecording()
                    }
                    isVoiceMode = true
                    isVoiceEntry = true
                }
            }
        }
    }
}

#Preview {
    JournalEntrySheet(
        journalText: .constant(""),
        selectedMood: .constant(nil),
        isVoiceEntry: .constant(false),
        prompt: "How has God shown His faithfulness to you this week?"
    )
}
