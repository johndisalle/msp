import Foundation
import AVFoundation
import SwiftUI

@Observable
final class AudioPlayerService {
    static let shared = AudioPlayerService()

    var isPlaying = false
    var isLoading = false
    var progress: Double = 0
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0
    var error: String?

    private var player: AVPlayer?
    private var timeObserver: Any?

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    var formattedRemaining: String {
        formatTime(max(0, duration - currentTime))
    }

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            self.error = "Failed to configure audio session"
        }
    }

    func play(url: URL) {
        stop()
        isLoading = true
        error = nil

        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        // Observe when the item is ready to play
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.didFinishPlaying()
        }

        // Observe status for errors
        playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    self.duration = playerItem.duration.seconds.isFinite ? playerItem.duration.seconds : 0
                    self.player?.play()
                    self.isPlaying = true
                    self.addTimeObserver()
                case .failed:
                    self.isLoading = false
                    self.error = "Failed to load audio"
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func play(urlString: String) {
        guard let url = URL(string: urlString) else {
            error = "Invalid audio URL"
            return
        }
        play(url: url)
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(to fraction: Double) {
        guard let player, duration > 0 else { return }
        let targetTime = CMTime(seconds: fraction * duration, preferredTimescale: 600)
        player.seek(to: targetTime)
    }

    func skipForward(_ seconds: TimeInterval = 15) {
        guard let player else { return }
        let target = CMTime(seconds: min(currentTime + seconds, duration), preferredTimescale: 600)
        player.seek(to: target)
    }

    func skipBackward(_ seconds: TimeInterval = 15) {
        guard let player else { return }
        let target = CMTime(seconds: max(currentTime - seconds, 0), preferredTimescale: 600)
        player.seek(to: target)
    }

    func stop() {
        player?.pause()
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        player = nil
        isPlaying = false
        isLoading = false
        progress = 0
        currentTime = 0
        duration = 0
        cancellables.removeAll()
    }

    private func didFinishPlaying() {
        isPlaying = false
        progress = 1.0
        currentTime = duration
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            if self.duration > 0 {
                self.progress = time.seconds / self.duration
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        guard seconds.isFinite else { return "0:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    // MARK: - Combine support for status observation

    private var cancellables = Set<AnyCancellable>()
}

import Combine
