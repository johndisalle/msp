import SwiftUI

struct PrayerTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var timerService: PrayerTimerService
    let onSave: () -> Void

    @State private var selectedMinutes = 5
    private let minuteOptions = [1, 3, 5, 10, 15, 20, 30]

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                // Timer display
                ZStack {
                    Circle()
                        .stroke(Color(.systemGray5), lineWidth: 8)
                        .frame(width: 220, height: 220)

                    Circle()
                        .trim(from: 0, to: timerService.progress)
                        .stroke(
                            Color.accentColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 220, height: 220)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: timerService.progress)

                    VStack(spacing: 4) {
                        Text(timerService.isRunning ? timerService.formattedRemaining : "\(selectedMinutes):00")
                            .font(.system(size: 48, weight: .light, design: .monospaced))

                        Text(timerService.isRunning ? "remaining" : "minutes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Duration picker (only when not running)
                if !timerService.isRunning && timerService.elapsedSeconds == 0 {
                    HStack(spacing: 12) {
                        ForEach(minuteOptions, id: \.self) { minutes in
                            Button {
                                selectedMinutes = minutes
                                timerService.targetMinutes = minutes
                            } label: {
                                Text("\(minutes)m")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedMinutes == minutes ? Color.accentColor : Color(.systemGray5))
                                    )
                                    .foregroundStyle(selectedMinutes == minutes ? .white : .primary)
                            }
                        }
                    }
                }

                // Controls
                HStack(spacing: 24) {
                    if timerService.elapsedSeconds > 0 {
                        Button {
                            timerService.reset()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.title2)
                                .frame(width: 56, height: 56)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        }
                    }

                    Button {
                        if timerService.isRunning {
                            timerService.pause()
                        } else {
                            timerService.targetMinutes = selectedMinutes
                            timerService.start()
                        }
                    } label: {
                        Image(systemName: timerService.isRunning ? "pause.fill" : "play.fill")
                            .font(.title)
                            .frame(width: 72, height: 72)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }

                    if timerService.elapsedSeconds > 0 && !timerService.isRunning {
                        Button {
                            onSave()
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .frame(width: 56, height: 56)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                }

                Spacer()

                if timerService.elapsedSeconds > 0 {
                    Text("Prayer time: \(timerService.formattedTime)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Prayer Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        if timerService.elapsedSeconds > 0 {
                            onSave()
                        }
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    PrayerTimerView(timerService: PrayerTimerService()) {}
}
