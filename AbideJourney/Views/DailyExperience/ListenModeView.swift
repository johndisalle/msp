import SwiftUI

struct ListenModeView: View {
    @Environment(\.dismiss) private var dismiss
    let scriptureRef: String
    let scriptureText: String
    let devotionalTitle: String
    let devotionalText: String
    let prayerText: String
    let dayNumber: Int
    let focusArea: String

    private var tts: TextToSpeechService { TextToSpeechService.shared }
    @State private var selectedSoundscape: AmbientSoundscape
    @State private var isPlaying = false
    @State private var showingSoundscapePicker = false
    @State private var pulseAnimation = false

    init(scriptureRef: String, scriptureText: String, devotionalTitle: String, devotionalText: String, prayerText: String, dayNumber: Int, focusArea: String) {
        self.scriptureRef = scriptureRef
        self.scriptureText = scriptureText
        self.devotionalTitle = devotionalTitle
        self.devotionalText = devotionalText
        self.prayerText = prayerText
        self.dayNumber = dayNumber
        self.focusArea = focusArea

        let saved = UserDefaults.standard.string(forKey: "preferredSoundscape") ?? AmbientSoundscape.none.rawValue
        _selectedSoundscape = State(initialValue: AmbientSoundscape(rawValue: saved) ?? .none)
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.14, blue: 0.22),
                    Color(red: 0.08, green: 0.10, blue: 0.18),
                    Color(red: 0.06, green: 0.07, blue: 0.14),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Decorative circles
            Circle()
                .fill(AJTheme.sage.opacity(0.06))
                .frame(width: 300, height: 300)
                .offset(x: -100, y: -200)
                .blur(radius: 60)

            Circle()
                .fill(AJTheme.gold.opacity(0.04))
                .frame(width: 250, height: 250)
                .offset(x: 120, y: 200)
                .blur(radius: 50)

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Day \(dayNumber)")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.7))
                        Text(focusArea)
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.4))
                    }

                    Spacer()

                    Button {
                        showingSoundscapePicker.toggle()
                    } label: {
                        Image(systemName: selectedSoundscape.icon)
                            .font(.title3)
                            .foregroundStyle(selectedSoundscape == .none ? .white.opacity(0.5) : selectedSoundscape.color)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Center content
                VStack(spacing: 24) {
                    // Album art style
                    ZStack {
                        // Outer glow
                        Circle()
                            .fill(AJTheme.sage.opacity(0.08))
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulseAnimation ? 1.08 : 1.0)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)

                        Circle()
                            .fill(AJTheme.sage.opacity(0.12))
                            .frame(width: 160, height: 160)

                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // Section label
                    if !tts.currentSection.isEmpty {
                        Text(tts.currentSection)
                            .font(.caption.bold())
                            .foregroundStyle(AJTheme.gold)
                            .textCase(.uppercase)
                            .tracking(2)
                            .transition(.opacity)
                    }

                    // Title
                    Text(devotionalTitle)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Text(scriptureRef)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.5))

                    // Progress bar
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(.white.opacity(0.1))
                                    .frame(height: 4)

                                Capsule()
                                    .fill(AJTheme.gold)
                                    .frame(width: geo.size.width * tts.progress, height: 4)
                                    .animation(.linear(duration: 0.3), value: tts.progress)
                            }
                        }
                        .frame(height: 4)

                        HStack {
                            Text(tts.currentSection.isEmpty ? "Ready" : "Playing")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                            if selectedSoundscape != .none {
                                HStack(spacing: 4) {
                                    Image(systemName: selectedSoundscape.icon)
                                        .font(.caption2)
                                    Text(selectedSoundscape.rawValue)
                                        .font(.caption2)
                                }
                                .foregroundStyle(selectedSoundscape.color.opacity(0.6))
                            }
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()

                // Controls
                HStack(spacing: 40) {
                    // Stop
                    Button {
                        tts.stop()
                        isPlaying = false
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }

                    // Play/Pause
                    Button {
                        if !isPlaying && !tts.isPaused {
                            startListening()
                        } else {
                            tts.togglePlayPause()
                            isPlaying = tts.isSpeaking
                        }
                    } label: {
                        Image(systemName: tts.isSpeaking ? "pause.fill" : "play.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(AJTheme.sage)
                            )
                            .shadow(color: AJTheme.sage.opacity(0.4), radius: 12)
                    }

                    // Soundscape toggle
                    Button {
                        cycleSoundscape()
                    } label: {
                        Image(systemName: "waveform.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                }
                .padding(.bottom, 20)

                // Soundscape picker
                if showingSoundscapePicker {
                    soundscapePicker
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Scripture preview
                VStack(spacing: 6) {
                    Text("\"\(String(scriptureText.prefix(100)))\(scriptureText.count > 100 ? "..." : "")\"")
                        .font(.caption.italic())
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    Text(scriptureRef)
                        .font(.caption2.bold())
                        .foregroundStyle(AJTheme.gold.opacity(0.5))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            pulseAnimation = true
            tts.setSoundscape(selectedSoundscape)
        }
        .onDisappear {
            tts.stop()
        }
    }

    // MARK: - Actions

    private func startListening() {
        tts.setSoundscape(selectedSoundscape)
        tts.speakDevotional(
            scripture: scriptureText,
            scriptureRef: scriptureRef,
            title: devotionalTitle,
            devotional: devotionalText,
            prayer: prayerText
        )
        isPlaying = true
    }

    private func cycleSoundscape() {
        let all = AmbientSoundscape.allCases
        guard let current = all.firstIndex(of: selectedSoundscape) else { return }
        let next = all[(current + 1) % all.count]
        selectedSoundscape = next
        tts.setSoundscape(next)
    }

    // MARK: - Soundscape Picker

    private var soundscapePicker: some View {
        VStack(spacing: 12) {
            Text("Ambient Sound")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                ForEach(AmbientSoundscape.allCases, id: \.self) { sound in
                    Button {
                        withAnimation {
                            selectedSoundscape = sound
                            tts.setSoundscape(sound)
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: sound.icon)
                                .font(.body)
                            Text(sound == .none ? "Off" : sound.rawValue.components(separatedBy: " ").first ?? "")
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedSoundscape == sound ? sound.color.opacity(0.2) : .white.opacity(0.05))
                        )
                        .foregroundStyle(selectedSoundscape == sound ? sound.color : .white.opacity(0.4))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

#Preview {
    ListenModeView(
        scriptureRef: "John 3:16",
        scriptureText: "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.",
        devotionalTitle: "The Greatest Love",
        devotionalText: "God's love is not passive. It is active, sacrificial, and personal.",
        prayerText: "Lord, help me understand the depth of Your love today.",
        dayNumber: 1,
        focusArea: "Knowing God"
    )
}
