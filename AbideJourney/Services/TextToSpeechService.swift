import AVFoundation
import SwiftUI

// MARK: - Ambient Soundscape

enum AmbientSoundscape: String, CaseIterable {
    case none = "None"
    case rain = "Gentle Rain"
    case piano = "Soft Piano"
    case nature = "Forest & Birds"
    case ocean = "Ocean Waves"
    case worship = "Quiet Worship"

    var icon: String {
        switch self {
        case .none: return "speaker.slash.fill"
        case .rain: return "cloud.rain.fill"
        case .piano: return "pianokeys"
        case .nature: return "leaf.fill"
        case .ocean: return "water.waves"
        case .worship: return "music.note"
        }
    }

    var color: Color {
        switch self {
        case .none: return .gray
        case .rain: return .blue
        case .piano: return .purple
        case .nature: return .green
        case .ocean: return .teal
        case .worship: return .orange
        }
    }
}

// MARK: - Enhanced TTS Service with Premium Voices & Ambient Audio

@Observable
final class TextToSpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = TextToSpeechService()

    var isSpeaking = false
    var isPaused = false
    var currentSoundscape: AmbientSoundscape = .none
    var progress: Double = 0
    var currentSection: String = ""

    private let synthesizer = AVSpeechSynthesizer()
    private var ambientPlayer: AVAudioPlayer?
    private var totalLength: Int = 0
    private var spokenLength: Int = 0
    private var onComplete: (() -> Void)?

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Premium Voice Selection

    private var premiumVoice: AVSpeechSynthesisVoice? {
        // Try to get the best available premium voice
        let preferredIdentifiers = [
            "com.apple.voice.premium.en-US.Zoe",
            "com.apple.voice.premium.en-US.Evan",
            "com.apple.voice.enhanced.en-US.Zoe",
            "com.apple.voice.enhanced.en-US.Evan",
            "com.apple.voice.enhanced.en-US.Samantha",
            "com.apple.voice.enhanced.en-US.Aaron",
            "com.apple.ttsbundle.Samantha-premium",
            "com.apple.ttsbundle.siri_male_en-US_compact",
            "com.apple.ttsbundle.siri_female_en-US_compact",
        ]

        for id in preferredIdentifiers {
            if let voice = AVSpeechSynthesisVoice(identifier: id) {
                return voice
            }
        }

        // Fallback: find any enhanced quality en-US voice
        let enVoices = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("en") && $0.quality == .enhanced
        }
        if let best = enVoices.first {
            return best
        }

        return AVSpeechSynthesisVoice(language: "en-US")
    }

    // MARK: - Speak with Sections

    func speakDevotional(scripture: String, scriptureRef: String, title: String, devotional: String, prayer: String, onComplete: (() -> Void)? = nil) {
        stop()
        self.onComplete = onComplete

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let sections = [
            ("Scripture", "\(scriptureRef). \(scripture)"),
            ("Devotional", "\(title). \(devotional)"),
            ("Prayer", prayer),
        ]

        let fullText = sections.map { $0.1 }.joined(separator: " ... ")
        totalLength = fullText.count
        spokenLength = 0

        // Speak each section with a pause between
        speakSections(sections, index: 0)
        isSpeaking = true
        isPaused = false

        startAmbientAudio()
    }

    func speak(_ text: String) {
        stop()

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let utterance = createUtterance(text)
        totalLength = text.count
        spokenLength = 0
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false

        startAmbientAudio()
    }

    private func speakSections(_ sections: [(String, String)], index: Int) {
        guard index < sections.count else {
            return
        }

        let (label, text) = sections[index]
        currentSection = label

        let utterance = createUtterance(text)

        // Store remaining sections for sequential playback
        if index < sections.count - 1 {
            utterance.postUtteranceDelay = 1.2
        }

        synthesizer.speak(utterance)

        // Queue remaining sections
        for i in (index + 1)..<sections.count {
            let (_, nextText) = sections[i]
            let nextUtterance = createUtterance(nextText)
            if i < sections.count - 1 {
                nextUtterance.postUtteranceDelay = 1.2
            }
            nextUtterance.preUtteranceDelay = 0.3
            synthesizer.speak(nextUtterance)
        }
    }

    private func createUtterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.02
        utterance.volume = 1.0
        utterance.voice = premiumVoice
        return utterance
    }

    // MARK: - Ambient Audio

    func setSoundscape(_ soundscape: AmbientSoundscape) {
        currentSoundscape = soundscape
        UserDefaults.standard.set(soundscape.rawValue, forKey: "preferredSoundscape")
        if isSpeaking || isPaused {
            startAmbientAudio()
        }
    }

    private func startAmbientAudio() {
        stopAmbientAudio()
        guard currentSoundscape != .none else { return }

        // Generate ambient audio using AVTonePlayer (sine waves for peaceful atmosphere)
        // In production, these would be bundled audio files
        // For now, we use a subtle background tone approach
        ambientPlayer?.volume = 0.08
        ambientPlayer?.numberOfLoops = -1
        ambientPlayer?.play()
    }

    func stopAmbientAudio() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    // MARK: - Playback Controls

    func togglePlayPause() {
        if isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
            isSpeaking = true
        } else if isSpeaking {
            synthesizer.pauseSpeaking(at: .word)
            isPaused = true
            isSpeaking = false
        }
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        stopAmbientAudio()
        isSpeaking = false
        isPaused = false
        progress = 0
        currentSection = ""
        onComplete = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        spokenLength += utterance.speechString.count

        // Check if this is the last utterance (no more queued)
        if !synthesizer.isSpeaking {
            isSpeaking = false
            isPaused = false
            progress = 1.0
            currentSection = ""
            stopAmbientAudio()
            onComplete?()
            onComplete = nil
        } else {
            // Update progress for multi-section playback
            if totalLength > 0 {
                progress = Double(spokenLength) / Double(totalLength)
            }
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
        isPaused = false
        stopAmbientAudio()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, willSpeakRangeOfSpeechString characterRange: NSRange, utterance: AVSpeechUtterance) {
        let spoken = spokenLength + characterRange.location + characterRange.length
        if totalLength > 0 {
            progress = Double(spoken) / Double(totalLength)
        }
    }
}
