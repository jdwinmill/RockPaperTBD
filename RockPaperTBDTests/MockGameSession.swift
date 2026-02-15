import Foundation
@testable import RockPaperTBD

@Observable
final class MockGameSession: GameSessionProtocol {
    var gameData: OnlineGameData?
    var roomCode: String = ""
    var role: PlayerRole = .host
    var isConnected: Bool = true
    var opponentDisconnected: Bool = false
    var error: String?
    var onUpdate: (() -> Void)?
    var onCreated: (() -> Void)?

    var createGameCalled = false
    var createGameBestOf: Int?
    var submitMoveCalled = false
    var submittedMove: Move?
    var clearRoundCalled = false
    var clearedRound: Int?
    var cleanupCalled = false
    var joinGameCode: String?

    func createGame(bestOf: Int) {
        createGameCalled = true
        createGameBestOf = bestOf
        roomCode = "TEST"
        onCreated?()
    }

    func joinGame(code: String, completion: @escaping (Bool) -> Void) {
        joinGameCode = code
        completion(true)
    }

    func submitMove(_ move: Move) {
        submitMoveCalled = true
        submittedMove = move
    }

    func clearRound(currentRound: Int) {
        clearRoundCalled = true
        clearedRound = currentRound
    }

    func cleanup() {
        cleanupCalled = true
    }
}
