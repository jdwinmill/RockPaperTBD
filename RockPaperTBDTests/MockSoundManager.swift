import Foundation
@testable import RockPaperTBD

final class MockSoundManager: SoundPlayable {
    var tapCount = 0
    var winCount = 0
    var loseCount = 0
    var tieCount = 0
    var countdownBeepSteps: [Int] = []
    var prepareHapticsCalled = false

    func playTap() { tapCount += 1 }
    func playWin() { winCount += 1 }
    func playLose() { loseCount += 1 }
    func playTie() { tieCount += 1 }
    func playCountdownBeep(step: Int) { countdownBeepSteps.append(step) }
    var battleTapCount = 0
    func playBattleTap(intensity: Double) { battleTapCount += 1 }
    func prepareHaptics() { prepareHapticsCalled = true }
}
