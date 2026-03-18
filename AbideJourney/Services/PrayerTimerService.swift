import Foundation
import Combine

@Observable
final class PrayerTimerService {
    var isRunning = false
    var elapsedSeconds: TimeInterval = 0
    var targetMinutes: Int = 5

    private var timer: Timer?
    private var startTime: Date?

    var elapsedMinutes: Int {
        Int(elapsedSeconds / 60)
    }

    var remainingSeconds: TimeInterval {
        max(0, TimeInterval(targetMinutes * 60) - elapsedSeconds)
    }

    var progress: Double {
        guard targetMinutes > 0 else { return 0 }
        return min(1.0, elapsedSeconds / TimeInterval(targetMinutes * 60))
    }

    var formattedTime: String {
        let total = Int(elapsedSeconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var formattedRemaining: String {
        let total = Int(remainingSeconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    func start() {
        isRunning = true
        startTime = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self, let startTime = self.startTime else { return }
            self.elapsedSeconds = Date().timeIntervalSince(startTime)

            if self.elapsedSeconds >= TimeInterval(self.targetMinutes * 60) {
                self.complete()
            }
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        elapsedSeconds = 0
        startTime = nil
    }

    func complete() {
        pause()
        // Session completed
    }
}
