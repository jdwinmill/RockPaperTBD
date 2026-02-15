import Foundation

protocol GameSessionProtocol: AnyObject {
    var gameData: OnlineGameData? { get set }
    var roomCode: String { get set }
    var role: PlayerRole { get set }
    var isConnected: Bool { get set }
    var opponentDisconnected: Bool { get set }
    var error: String? { get set }
    var onUpdate: (() -> Void)? { get set }
    var onCreated: (() -> Void)? { get set }

    func createGame(bestOf: Int, tapBattleMode: TapBattleMode)
    func joinGame(code: String, completion: @escaping (Bool) -> Void)
    func submitMove(_ move: Move)
    func submitTapCount(_ count: Int)
    func clearRound(currentRound: Int)
    func cleanup()
}

protocol SoundPlayable {
    func playTap()
    func playWin()
    func playLose()
    func playTie()
    func playCountdownBeep(step: Int)
    func playBattleTap(intensity: Double)
    func prepareHaptics()
}
