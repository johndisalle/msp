import SwiftUI
import UIKit

struct CheckInSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRating: CheckInRating?
    @State private var note = ""
    let onSubmit: (CheckInRating, String?) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Text("How did today's step go?")
                    .font(.title2.bold())

                HStack(spacing: 16) {
                    ForEach(CheckInRating.allCases, id: \.self) { rating in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedRating = rating
                            }
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            VStack(spacing: 6) {
                                Text(rating.icon)
                                    .font(.system(size: selectedRating == rating ? 44 : 32))
                                Text(rating.label)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedRating == rating ? Color.accentColor.opacity(0.15) : .clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(rating.label)
                        .accessibilityAddTraits(selectedRating == rating ? .isSelected : [])
                    }
                }

                TextField("Add a note (optional)", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    guard let rating = selectedRating else { return }
                    onSubmit(rating, note.isEmpty ? nil : note)
                    dismiss()
                } label: {
                    Text("Submit")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedRating != nil ? Color.accentColor : Color(.systemGray4))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedRating == nil)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .navigationTitle("Evening Check-In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    CheckInSheet { rating, note in
        print("Rating: \(rating), Note: \(note ?? "none")")
    }
}
