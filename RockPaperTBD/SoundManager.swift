import AVFoundation
import UIKit

@Observable
final class SoundManager {
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()

    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private let sampleRate: Double = 44100
    private var format: AVAudioFormat?

    // Pre-generated buffers
    private var countdownBuffers: [Int: AVAudioPCMBuffer] = [:]
    private var tapBuffer: AVAudioPCMBuffer?
    private var winBuffers: [AVAudioPCMBuffer] = []
    private var tieBuffers: [AVAudioPCMBuffer] = []

    init() {
        setupEngine()
        generateBuffers()
        prepareHaptics()
    }

    private func setupEngine() {
        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: fmt)

        do {
            try engine.start()
        } catch {
            return
        }

        player.play()
        self.engine = engine
        self.playerNode = player
        self.format = fmt
    }

    private func generateBuffers() {
        // Countdown beeps
        countdownBuffers[3] = makeBuffer(frequency: 400, duration: 0.1)
        countdownBuffers[2] = makeBuffer(frequency: 500, duration: 0.1)
        countdownBuffers[1] = makeBuffer(frequency: 600, duration: 0.1)
        countdownBuffers[0] = makeBuffer(frequency: 800, duration: 0.3)

        // Tap
        tapBuffer = makeBuffer(frequency: 1000, duration: 0.05)

        // Win arpeggio
        winBuffers = [
            makeBuffer(frequency: 880, duration: 0.15),
            makeBuffer(frequency: 1100, duration: 0.15),
            makeBuffer(frequency: 1320, duration: 0.25),
        ].compactMap { $0 }

        // Tie
        tieBuffers = [
            makeBuffer(frequency: 440, duration: 0.2),
            makeBuffer(frequency: 380, duration: 0.2),
        ].compactMap { $0 }

    }

    func playCountdownBeep(step: Int) {
        switch step {
        case 3, 2: impactMedium.impactOccurred()
        case 1: impactHeavy.impactOccurred()
        default: impactHeavy.impactOccurred(intensity: 1.0)
        }
        if let buffer = countdownBuffers[step] {
            scheduleBuffer(buffer)
        }
    }

    func playTap() {
        impactLight.impactOccurred()
        if let buffer = tapBuffer {
            scheduleBuffer(buffer)
        }
    }

    func playWin() {
        notification.notificationOccurred(.success)
        guard winBuffers.count == 3 else { return }
        scheduleBuffer(winBuffers[0])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else { return }
            self.scheduleBuffer(self.winBuffers[1])
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            guard let self else { return }
            self.scheduleBuffer(self.winBuffers[2])
        }
    }

    func playTie() {
        notification.notificationOccurred(.warning)
        guard tieBuffers.count == 2 else { return }
        scheduleBuffer(tieBuffers[0])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            self.scheduleBuffer(self.tieBuffers[1])
        }
    }

    func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        notification.prepare()
    }

    private func scheduleBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let player = playerNode, engine?.isRunning == true else {
            // Engine died, try to restart
            setupEngine()
            playerNode?.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            return
        }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func makeBuffer(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let fmt = format,
              let buffer = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: frameCount) else {
            return nil
        }

        buffer.frameLength = frameCount
        let data = buffer.floatChannelData![0]

        let attackEnd = min(0.005, duration * 0.1)
        let releaseStart = duration - min(0.01, duration * 0.2)

        for i in 0..<Int(frameCount) {
            let t = Double(i) / sampleRate
            let envelope: Float
            if t < attackEnd {
                envelope = Float(t / attackEnd)
            } else if t > releaseStart {
                envelope = Float((duration - t) / (duration - releaseStart))
            } else {
                envelope = 1.0
            }
            data[i] = Float(sin(2.0 * .pi * frequency * t)) * 0.4 * envelope
        }

        return buffer
    }
}
