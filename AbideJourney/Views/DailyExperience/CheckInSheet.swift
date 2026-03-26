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
                    .font(AJTheme.headlineFont)
                    .foregroundColor(AJTheme.primaryText)

                HStack(spacing: 16) {
                    ForEach(CheckInRating.allCases, id: \.self) { rating in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedRating = rating
                            }
                            UISelectionFeedbackGenerator().selectionChanged()
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: rating.sfSymbol)
                                    .font(.system(size: selectedRating == rating ? 36 : 26))
                                    .foregroundStyle(rating.color)
                                    .frame(height: selectedRating == rating ? 44 : 32)
                                Text(rating.label)
                                    .font(.caption2)
                                    .foregroundStyle(AJTheme.secondaryText)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedRating == rating ? AJTheme.sage.opacity(0.15) : .clear)
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
                        .font(AJTheme.subheadlineFont)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedRating != nil ? AJTheme.sage : AJTheme.sandstone)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(selectedRating == nil)
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
            .ajScreenBackground()
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
