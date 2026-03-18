import SwiftUI

struct JournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var journalText: String
    @Binding var selectedMood: Mood?
    let prompt: String
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflection Prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(prompt)
                            .font(.body)
                            .italic()
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.accentColor.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Mood selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How are you feeling?")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                Button {
                                    selectedMood = mood
                                } label: {
                                    VStack(spacing: 4) {
                                        Text(mood.rawValue)
                                            .font(.title)
                                        Text(mood.label)
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(selectedMood == mood ? Color.accentColor.opacity(0.15) : .clear)
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(mood.label)
                                .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
                            }
                        }
                    }

                    // Journal entry
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Reflection")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextEditor(text: $journalText)
                            .frame(minHeight: 200)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isFocused)
                    }
                }
                .padding()
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { dismiss() }
                        .bold()
                }
            }
            .onAppear { isFocused = true }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    JournalEntrySheet(
        journalText: .constant(""),
        selectedMood: .constant(nil),
        prompt: "How has God shown His faithfulness to you this week?"
    )
}
