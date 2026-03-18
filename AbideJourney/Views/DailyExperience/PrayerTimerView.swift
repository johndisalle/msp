import SwiftUI
import UIKit

struct PrayerTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var timerService: PrayerTimerService
    let onSave: () -> Void
    var focusArea: DiscipleshipArea?
    var scriptureReference: String?

    @State private var selectedMinutes = 5
    @State private var currentPromptIndex = 0
    @State private var showingGuide = true
    private let minuteOptions = [1, 3, 5, 10, 15, 20, 30]

    private var prompts: [PrayerPrompt] {
        PrayerPrompt.prompts(for: focusArea)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // Prayer guide card (shown before and during prayer)
                    if showingGuide {
                        prayerGuideCard
                    }

                    // Timer display
                    timerDisplay

                    // Rotating prayer prompts while timer is running
                    if timerService.isRunning {
                        rotatingPrompt
                    }

                    // Duration picker (only when not running)
                    if !timerService.isRunning && timerService.elapsedSeconds == 0 {
                        durationPicker
                    }

                    // Controls
                    controlButtons

                    if timerService.elapsedSeconds > 0 {
                        Text("Prayer time: \(timerService.formattedTime)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation { showingGuide.toggle() }
                    } label: {
                        Image(systemName: showingGuide ? "lightbulb.fill" : "lightbulb")
                            .foregroundStyle(showingGuide ? .yellow : .secondary)
                    }
                    .accessibilityLabel(showingGuide ? "Hide prayer guide" : "Show prayer guide")
                }
            }
        }
        .presentationDetents([.large])
        .onReceive(Timer.publish(every: 15, on: .main, in: .common).autoconnect()) { _ in
            if timerService.isRunning {
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentPromptIndex = (currentPromptIndex + 1) % prompts.count
                }
            }
        }
    }

    // MARK: - Prayer Guide Card

    private var prayerGuideCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "hands.sparkles.fill")
                    .foregroundStyle(.yellow)
                Text("Not sure how to pray?")
                    .font(.headline)
            }

            Text("Prayer is simply talking to God. There's no wrong way to do it. Here's a simple pattern to get you started:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 12) {
                PrayerStepRow(
                    number: "1",
                    title: "Thank Him",
                    description: "Start by thanking God for something specific today.",
                    color: .green
                )
                PrayerStepRow(
                    number: "2",
                    title: "Be Honest",
                    description: "Tell God what's on your heart — worries, joys, questions. He can handle it all.",
                    color: .blue
                )
                PrayerStepRow(
                    number: "3",
                    title: "Ask",
                    description: "Pray for your needs and for others. Nothing is too small.",
                    color: .purple
                )
                PrayerStepRow(
                    number: "4",
                    title: "Listen",
                    description: "Sit quietly for a moment. God speaks through peace, through His Word, and through the stillness.",
                    color: .orange
                )
            }

            if let ref = scriptureReference {
                HStack(spacing: 6) {
                    Image(systemName: "text.book.closed.fill")
                        .font(.caption)
                        .foregroundStyle(.accent)
                    Text("Try praying today's scripture back to God: \(ref)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
        )
        .accessibilityElement(children: .combine)
    }

    // MARK: - Timer Display

    private var timerDisplay: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 8)
                .frame(width: 200, height: 200)

            Circle()
                .trim(from: 0, to: timerService.progress)
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 200, height: 200)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerService.progress)

            VStack(spacing: 4) {
                Text(timerService.isRunning ? timerService.formattedRemaining : "\(selectedMinutes):00")
                    .font(.system(size: 44, weight: .light, design: .monospaced))

                Text(timerService.isRunning ? "remaining" : "minutes")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(timerService.isRunning
            ? "Prayer timer, \(timerService.formattedRemaining) remaining"
            : "Prayer timer, \(selectedMinutes) minutes selected")
        .accessibilityValue("\(Int(timerService.progress * 100)) percent complete")
    }

    // MARK: - Rotating Prompt

    private var rotatingPrompt: some View {
        let prompt = prompts[currentPromptIndex]
        return VStack(spacing: 8) {
            Text(prompt.category)
                .font(.caption.bold())
                .foregroundStyle(.accent)
                .textCase(.uppercase)

            Text(prompt.text)
                .font(.body)
                .italic()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .id(currentPromptIndex) // Force transition on change
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.accentColor.opacity(0.08))
        )
        .accessibilityLabel("Prayer prompt: \(prompt.text)")
    }

    // MARK: - Duration Picker

    private var durationPicker: some View {
        HStack(spacing: 12) {
            ForEach(minuteOptions, id: \.self) { minutes in
                Button {
                    selectedMinutes = minutes
                    timerService.targetMinutes = minutes
                    UISelectionFeedbackGenerator().selectionChanged()
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
                .accessibilityLabel("\(minutes) minutes")
                .accessibilityAddTraits(selectedMinutes == minutes ? .isSelected : [])
            }
        }
    }

    // MARK: - Control Buttons

    private var controlButtons: some View {
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
                .accessibilityLabel("Reset timer")
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
            .accessibilityLabel(timerService.isRunning ? "Pause prayer" : "Start prayer")

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
                .accessibilityLabel("Save prayer session")
            }
        }
    }
}

// MARK: - Prayer Step Row

struct PrayerStepRow: View {
    let number: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(color.opacity(0.15))
                .foregroundStyle(color)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Prayer Prompts

struct PrayerPrompt {
    let category: String
    let text: String

    static func prompts(for area: DiscipleshipArea?) -> [PrayerPrompt] {
        var result = generalPrompts
        if let area {
            result.append(contentsOf: areaPrompts(for: area))
        }
        return result
    }

    static let generalPrompts: [PrayerPrompt] = [
        PrayerPrompt(category: "Gratitude", text: "\"God, thank You for...\" Name one thing you're grateful for right now."),
        PrayerPrompt(category: "Honesty", text: "\"God, I'm feeling...\" Tell Him honestly what's on your heart today."),
        PrayerPrompt(category: "Request", text: "\"God, I need Your help with...\" He already knows, but He loves hearing from you."),
        PrayerPrompt(category: "Others", text: "\"God, please be with...\" Think of someone who needs prayer today."),
        PrayerPrompt(category: "Listening", text: "Pause. Take a slow breath. Ask God, \"What do You want me to know today?\""),
        PrayerPrompt(category: "Trust", text: "\"God, I'm choosing to trust You with...\" Name something you can't control."),
        PrayerPrompt(category: "Worship", text: "\"God, You are...\" Tell Him one thing you love about who He is."),
        PrayerPrompt(category: "Surrender", text: "\"God, I give You my day. Lead me where You want me to go.\""),
    ]

    static func areaPrompts(for area: DiscipleshipArea) -> [PrayerPrompt] {
        switch area {
        case .prayer:
            return [
                PrayerPrompt(category: "Going Deeper", text: "Ask God to teach you to enjoy prayer, not just do it as a task."),
                PrayerPrompt(category: "Going Deeper", text: "\"God, make prayer feel less like a duty and more like coming home.\""),
            ]
        case .scripture:
            return [
                PrayerPrompt(category: "The Word", text: "Pray today's scripture back to God. Make it personal — put your name in it."),
                PrayerPrompt(category: "The Word", text: "\"God, open my eyes to see something new in Your Word today.\""),
            ]
        case .obedience:
            return [
                PrayerPrompt(category: "Obedience", text: "\"God, is there something You've been asking me to do that I've been putting off?\""),
                PrayerPrompt(category: "Obedience", text: "\"Give me the courage to do the next right thing, even when it's hard.\""),
            ]
        case .worship:
            return [
                PrayerPrompt(category: "Worship", text: "Think about who God is — His patience, His kindness, His power. Tell Him what amazes you."),
                PrayerPrompt(category: "Worship", text: "\"God, I worship You not for what You do, but for who You are.\""),
            ]
        case .community:
            return [
                PrayerPrompt(category: "Community", text: "Pray for someone in your life who is going through a hard time."),
                PrayerPrompt(category: "Community", text: "\"God, show me how to love the people around me the way You love me.\""),
            ]
        case .evangelism:
            return [
                PrayerPrompt(category: "Sharing", text: "Think of one person who doesn't know Jesus. Pray for them by name."),
                PrayerPrompt(category: "Sharing", text: "\"God, give me the right words and the right moment to share Your love.\""),
            ]
        case .service:
            return [
                PrayerPrompt(category: "Service", text: "\"God, open my eyes to one person I can help today — even in a small way.\""),
                PrayerPrompt(category: "Service", text: "\"Let my hands be Your hands today. Show me where I'm needed.\""),
            ]
        }
    }
}

#Preview {
    PrayerTimerView(
        timerService: PrayerTimerService(),
        onSave: {},
        focusArea: .prayer,
        scriptureReference: "Jeremiah 29:12-13"
    )
}
