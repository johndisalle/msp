import AVFoundation
import CryptoKit
import UIKit

/// Provides premium ElevenLabs voice narration for Listen Mode.
/// Falls back to on-device TTS if the Cloud Function is unavailable.
@MainActor
@Observable
final class AudioNarrationService: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioNarrationService()

    enum NarrationVoice: String, CaseIterable {
        case female = "female"
        case male = "male"

        var label: String {
            switch self {
            case .female: return "Sarah"
            case .male: return "David"
            }
        }

        var icon: String {
            switch self {
            case .female: return "person.circle.fill"
            case .male: return "person.circle"
            }
        }
    }

    enum PlaybackState {
        case idle
        case loading
        case playing
        case paused
    }

    var state: PlaybackState = .idle
    var progress: Double = 0
    var currentSection: String = ""
    var selectedVoice: NarrationVoice = {
        let saved = UserDefaults.standard.string(forKey: "narrationVoice") ?? "female"
        return NarrationVoice(rawValue: saved) ?? .female
    }()

    private var audioPlayer: AVAudioPlayer?
    private var ambientPlayer: AVAudioPlayer?
    private var progressTimer: Timer?
    var currentSoundscape: AmbientSoundscape = .none
    private var onComplete: (() -> Void)?

    private let cloudFunctionBaseURL: String? = {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "CLOUD_FUNCTION_URL") as? String else {
            return nil
        }
        // Derive base URL from the journey endpoint
        return url.replacingOccurrences(of: "/generateJourneyHTTP", with: "")
    }()

    private let appSecret: String? = {
        (Bundle.main.object(forInfoDictionaryKey: "APP_SECRET") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }()

    private override init() {
        super.init()
    }

    // MARK: - Public API

    func setVoice(_ voice: NarrationVoice) {
        selectedVoice = voice
        UserDefaults.standard.set(voice.rawValue, forKey: "narrationVoice")
    }

    func speakDevotional(
        scripture: String,
        scriptureRef: String,
        title: String,
        devotional: String,
        prayer: String,
        journeyId: String = "",
        dayNumber: Int = 0,
        onComplete: (() -> Void)? = nil
    ) {
        stop()
        self.onComplete = onComplete

        let narrationScript = formatScript(
            scriptureRef: scriptureRef,
            scripture: scripture,
            title: title,
            devotional: devotional,
            prayer: prayer
        )

        // Check cache first
        let cacheKey = audioCacheKey(journeyId: journeyId, dayNumber: dayNumber, voice: selectedVoice)
        if let cachedURL = getCachedAudio(key: cacheKey) {
            playAudioFile(url: cachedURL)
            return
        }

        // Try Cloud Function
        guard let baseURL = cloudFunctionBaseURL,
              let secret = appSecret,
              !secret.isEmpty else {
            // No cloud function configured — use on-device TTS
            fallbackToDeviceTTS(scripture: scripture, scriptureRef: scriptureRef, title: title, devotional: devotional, prayer: prayer, onComplete: onComplete)
            return
        }

        state = .loading
        currentSection = "Preparing narration..."

        Task {
            do {
                let audioData = try await fetchAudio(
                    baseURL: baseURL,
                    secret: secret,
                    text: narrationScript,
                    voice: selectedVoice
                )

                guard !audioData.isEmpty else {
                    throw NSError(domain: "AudioNarration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Empty audio data"])
                }

                // Cache it
                let cachedURL = cacheAudio(data: audioData, key: cacheKey)
                playAudioFile(url: cachedURL)
            } catch {
                #if DEBUG
                print("[AudioNarration] Cloud Function failed: \(error.localizedDescription). Falling back to device TTS.")
                #endif
                // Fallback to on-device TTS
                fallbackToDeviceTTS(scripture: scripture, scriptureRef: scriptureRef, title: title, devotional: devotional, prayer: prayer, onComplete: onComplete)
            }
        }
    }

    func togglePlayPause() {
        switch state {
        case .playing:
            audioPlayer?.pause()
            state = .paused
        case .paused:
            audioPlayer?.play()
            state = .playing
            startProgressTimer()
        default:
            break
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopAmbientAudio()
        progressTimer?.invalidate()
        progressTimer = nil
        state = .idle
        progress = 0
        currentSection = ""
        onComplete = nil
    }

    // MARK: - Audio Fetching

    private func fetchAudio(baseURL: String, secret: String, text: String, voice: NarrationVoice) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/generateAudioHTTP") else {
            throw NSError(domain: "AudioNarration", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(secret, forHTTPHeaderField: "X-App-Secret")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "text": text,
            "voice": voice.rawValue,
            "deviceId": deviceId,
            "appSecret": secret
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        #if DEBUG
        print("[AudioNarration] Requesting audio from: \(url.absoluteString)")
        print("[AudioNarration] Text length: \(text.count), voice: \(voice.rawValue)")
        #endif
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "AudioNarration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        #if DEBUG
        print("[AudioNarration] Response: \(httpResponse.statusCode), size: \(data.count) bytes")
        #endif

        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data.prefix(500), encoding: .utf8) ?? "unknown"
            #if DEBUG
            print("[AudioNarration] Error: \(errorBody)")
            #endif
            throw NSError(domain: "AudioNarration", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorBody)"])
        }

        guard data.count > 1000 else {
            throw NSError(domain: "AudioNarration", code: 2, userInfo: [NSLocalizedDescriptionKey: "Response too small to be audio (\(data.count) bytes)"])
        }

        return data
    }

    // MARK: - Playback

    private func playAudioFile(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            state = .playing
            currentSection = "Playing"
            startProgressTimer()
            startAmbientAudio()
        } catch {
            state = .idle
            onComplete?()
            onComplete = nil
        }
    }

    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let player = self.audioPlayer else { return }
                if player.duration > 0 {
                    self.progress = player.currentTime / player.duration
                }

                // Update section label based on progress
                let pct = self.progress
                if pct < 0.25 {
                    self.currentSection = "Scripture"
                } else if pct < 0.85 {
                    self.currentSection = "Devotional"
                } else {
                    self.currentSection = "Prayer"
                }
            }
        }
    }

    // MARK: - AVAudioPlayerDelegate

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.state = .idle
            self.progress = 1.0
            self.currentSection = ""
            self.progressTimer?.invalidate()
            self.progressTimer = nil
            self.stopAmbientAudio()
            self.onComplete?()
            self.onComplete = nil
        }
    }

    // MARK: - Ambient Audio

    func setSoundscape(_ soundscape: AmbientSoundscape) {
        currentSoundscape = soundscape
        UserDefaults.standard.set(soundscape.rawValue, forKey: "preferredSoundscape")
        if state == .playing || state == .paused {
            startAmbientAudio()
        }
    }

    private func startAmbientAudio() {
        stopAmbientAudio()
        guard currentSoundscape != .none else { return }

        let sampleRate: Double = 44100
        let duration: Double = 10.0
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
            let fadeFrames = Int(sampleRate * 0.5)
            if i < fadeFrames {
                sample *= Float(i) / Float(fadeFrames)
            } else if i > frameCount - fadeFrames {
                sample *= Float(frameCount - i) / Float(fadeFrames)
            }
            audioData[i] = sample
        }

        let bytesPerSample = 2
        let dataSize = frameCount * bytesPerSample
        var wavData = Data()

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

        for sample in audioData {
            var intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            wavData.append(Data(bytes: &intSample, count: 2))
        }

        do {
            ambientPlayer = try AVAudioPlayer(data: wavData)
            ambientPlayer?.volume = 0.08
            ambientPlayer?.numberOfLoops = -1
            ambientPlayer?.play()
        } catch {}
    }

    func stopAmbientAudio() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }

    // MARK: - Caching

    private func audioCacheKey(journeyId: String, dayNumber: Int, voice: NarrationVoice) -> String {
        let raw = "\(journeyId)_day\(dayNumber)_\(voice.rawValue)"
        let hash = SHA256.hash(data: Data(raw.utf8))
        return hash.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    private var cacheDirectory: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("narration_audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func getCachedAudio(key: String) -> URL? {
        let url = cacheDirectory.appendingPathComponent("\(key).mp3")
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func cacheAudio(data: Data, key: String) -> URL {
        let url = cacheDirectory.appendingPathComponent("\(key).mp3")
        try? data.write(to: url)
        return url
    }

    // MARK: - Fallback

    private func fallbackToDeviceTTS(
        scripture: String,
        scriptureRef: String,
        title: String,
        devotional: String,
        prayer: String,
        onComplete: (() -> Void)?
    ) {
        // Use the existing TTS service and mirror its state to ours
        let tts = TextToSpeechService.shared
        state = .playing
        currentSection = "Scripture"

        tts.speakDevotional(
            scripture: scripture,
            scriptureRef: scriptureRef,
            title: title,
            devotional: devotional,
            prayer: prayer
        ) { [weak self] in
            self?.state = .idle
            self?.progress = 1.0
            self?.currentSection = ""
            onComplete?()
        }

        // Poll TTS progress to update our state
        usingDeviceTTS = true
        startTTSProgressPolling()
    }

    private var usingDeviceTTS = false
    private var ttsPollingTimer: Timer?

    private func startTTSProgressPolling() {
        ttsPollingTimer?.invalidate()
        ttsPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.usingDeviceTTS else { return }
                let tts = TextToSpeechService.shared
                self.progress = tts.progress
                self.currentSection = tts.currentSection

                if !tts.isSpeaking && !tts.isPaused && self.progress > 0 {
                    self.ttsPollingTimer?.invalidate()
                    self.ttsPollingTimer = nil
                    self.usingDeviceTTS = false
                    self.state = .idle
                    self.progress = 1.0
                }
            }
        }
    }

    // MARK: - Script Formatting

    private func formatScript(
        scriptureRef: String,
        scripture: String,
        title: String,
        devotional: String,
        prayer: String
    ) -> String {
        """
        \(title).

        Today's Scripture comes from \(scriptureRef).

        \(scripture)

        \(devotional)

        Let us pray together.

        \(prayer)

        Amen.
        """
    }
}
