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

        // Generate a gentle ambient tone using synthesized audio data
        // Each soundscape creates a unique frequency blend for atmosphere
        let sampleRate: Double = 44100
        let duration: Double = 10.0 // 10-second loop
        let frameCount = Int(sampleRate * duration)

        var audioData = [Float](repeating: 0, count: frameCount)
        let frequencies: [Double]

        switch currentSoundscape {
        case .rain: frequencies = [220, 330, 440]
        case .piano: frequencies = [261.63, 329.63, 392.00]
        case .nature: frequencies = [196, 293.66, 349.23]
        case .ocean: frequencies = [174.61, 261.63, 349.23]
        case .worship: frequencies = [293.66, 369.99, 440]
        case .none: return
        }

        for i in 0..<frameCount {
            var sample: Float = 0
            for freq in frequencies {
                let t = Double(i) / sampleRate
                sample += Float(sin(2.0 * .pi * freq * t) * 0.05)
            }
            // Fade envelope for smooth looping
            let fadeFrames = Int(sampleRate * 0.5)
            if i < fadeFrames {
                sample *= Float(i) / Float(fadeFrames)
            } else if i > frameCount - fadeFrames {
                sample *= Float(frameCount - i) / Float(fadeFrames)
            }
            audioData[i] = sample
        }

        // Create WAV data in memory
        let bytesPerSample = 2
        let dataSize = frameCount * bytesPerSample
        var wavData = Data()

        // WAV header
        wavData.append(contentsOf: [UInt8]("RIFF".utf8))
        var fileSize = UInt32(36 + dataSize).littleEndian
        wavData.append(Data(bytes: &fileSize, count: 4))
        wavData.append(contentsOf: [UInt8]("WAVE".utf8))
        wavData.append(contentsOf: [UInt8]("fmt ".utf8))
        var chunkSize: UInt32 = 16; wavData.append(Data(bytes: &chunkSize, count: 4))
        var audioFormat: UInt16 = 1; wavData.append(Data(bytes: &audioFormat, count: 2))
        var channels: UInt16 = 1; wavData.append(Data(bytes: &channels, count: 2))
        var rate = UInt32(sampleRate).littleEndian; wavData.append(Data(bytes: &rate, count: 4))
        var byteRate = UInt32(sampleRate * Double(bytesPerSample)).littleEndian; wavData.append(Data(bytes: &byteRate, count: 4))
        var blockAlign = UInt16(bytesPerSample).littleEndian; wavData.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: UInt16 = 16; wavData.append(Data(bytes: &bitsPerSample, count: 2))
        wavData.append(contentsOf: [UInt8]("data".utf8))
        var dataChunkSize = UInt32(dataSize).littleEndian; wavData.append(Data(bytes: &dataChunkSize, count: 4))

        // Audio samples
        for sample in audioData {
            var intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            wavData.append(Data(bytes: &intSample, count: 2))
        }

        do {
            ambientPlayer = try AVAudioPlayer(data: wavData)
            ambientPlayer?.volume = 0.08
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.play()
        } catch {
            // Ambient audio is optional — continue without it
        }
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
