import Foundation
import FirebaseDatabase

@Observable
final class GameSession: GameSessionProtocol {
    var gameData: OnlineGameData?
    var roomCode: String = ""
    var role: PlayerRole = .host
    var isConnected: Bool = true
    var opponentDisconnected: Bool = false
    var error: String?

    var onUpdate: (() -> Void)?

    private var gameRef: DatabaseReference?
    private var observerHandle: DatabaseHandle?
    private var connectedHandle: DatabaseHandle?
    private var guestJoined: Bool = false

    var onCreated: (() -> Void)?

    func createGame(bestOf: Int, tapBattleMode: TapBattleMode) {
        role = .host
        attemptCreateGame(bestOf: bestOf, tapBattleMode: tapBattleMode, retriesLeft: 5)
    }

    private func attemptCreateGame(bestOf: Int, tapBattleMode: TapBattleMode, retriesLeft: Int) {
        let code = RoomCode.generate()
        let ref = Database.database().reference().child(FirebasePath.games).child(code)

        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self else { return }
                if snapshot.exists() && retriesLeft > 0 {
                    self.attemptCreateGame(bestOf: bestOf, tapBattleMode: tapBattleMode, retriesLeft: retriesLeft - 1)
                    return
                }

                self.roomCode = code
                self.gameRef = ref

                var data: [String: Any] = [
                    "hostId": PlayerIdentity.id,
                    "hostName": DisplayName.saved ?? "Player 1",
                    "bestOf": bestOf,
                    "currentRound": 1,
                    "timestamp": ServerValue.timestamp()
                ]
                if tapBattleMode != .tiesOnly {
                    data["tapBattleMode"] = tapBattleMode.rawValue
                }

                ref.setValue(data)
                // Only auto-delete abandoned lobbies (before guest joins)
                ref.onDisconnectRemoveValue()
                self.observeGame()
                self.observeConnection()
                self.onCreated?()
            }
        }
    }

    func joinGame(code: String, completion: @escaping (Bool) -> Void) {
        let upperCode = code.uppercased()
        roomCode = upperCode
        role = .guest

        let ref = Database.database().reference().child(FirebasePath.games).child(upperCode)
        gameRef = ref

        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self else { return }
                guard snapshot.exists(),
                      let dict = snapshot.value as? [String: Any],
                      dict["hostId"] != nil,
                      dict["guestId"] == nil else {
                    self.error = "Game not found or already full"
                    completion(false)
                    return
                }

                ref.child("guestId").setValue(PlayerIdentity.id)
                ref.child("guestName").setValue(DisplayName.saved ?? "Player 2")
                ref.child("guestId").onDisconnectRemoveValue()
                ref.child("guestName").onDisconnectRemoveValue()
                ref.child("guestMove").onDisconnectRemoveValue()
                ref.child("guestTaps").onDisconnectRemoveValue()
                self.observeGame()
                self.observeConnection()
                completion(true)
            }
        }
    }

    func submitMove(_ move: Move) {
        let field = role == .host ? "hostMove" : "guestMove"
        gameRef?.child(field).setValue(move.rawValue)
    }

    func submitTapCount(_ count: Int) {
        let field = role == .host ? "hostTaps" : "guestTaps"
        gameRef?.child(field).setValue(count)
    }

    func clearRound(currentRound: Int) {
        guard role == .host else { return }
        gameRef?.updateChildValues([
            "hostMove": NSNull(),
            "guestMove": NSNull(),
            "hostTaps": NSNull(),
            "guestTaps": NSNull(),
            "currentRound": currentRound
        ])
    }

    private func observeGame() {
        guard let ref = gameRef else { return }
        observerHandle = ref.observe(.value) { [weak self] snapshot in
            let value = snapshot.value
            let exists = snapshot.exists()
            DispatchQueue.main.async {
                guard let self else { return }
                guard exists, let dict = value as? [String: Any] else {
                    self.opponentDisconnected = true
                    self.onUpdate?()
                    return
                }

                let data = OnlineGameData(
                    hostId: dict["hostId"] as? String ?? "",
                    guestId: dict["guestId"] as? String,
                    hostName: dict["hostName"] as? String,
                    guestName: dict["guestName"] as? String,
                    bestOf: dict["bestOf"] as? Int ?? 3,
                    hostMove: dict["hostMove"] as? String,
                    guestMove: dict["guestMove"] as? String,
                    hostTaps: dict["hostTaps"] as? Int,
                    guestTaps: dict["guestTaps"] as? Int,
                    tapBattleMode: dict["tapBattleMode"] as? String,
                    currentRound: dict["currentRound"] as? Int ?? 1,
                    timestamp: dict["timestamp"] as? TimeInterval ?? 0
                )

                // When guest joins, replace the lobby-cleanup onDisconnect
                // with a targeted one so brief host disconnects don't nuke the game
                if self.role == .host && !self.guestJoined && data.guestId != nil {
                    ref.cancelDisconnectOperations()
                    ref.child("hostId").onDisconnectRemoveValue()
                    ref.child("hostName").onDisconnectRemoveValue()
                    ref.child("hostMove").onDisconnectRemoveValue()
                    ref.child("hostTaps").onDisconnectRemoveValue()
                }

                if self.role == .host && self.guestJoined && data.guestId == nil {
                    self.opponentDisconnected = true
                }
                if self.role == .guest && self.guestJoined && data.hostId.isEmpty {
                    self.opponentDisconnected = true
                }
                if data.guestId != nil {
                    self.guestJoined = true
                }

                self.gameData = data
                self.onUpdate?()
            }
        }
    }

    private func observeConnection() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedHandle = connectedRef.observe(.value) { [weak self] snapshot in
            let connected = snapshot.value as? Bool ?? false
            DispatchQueue.main.async {
                guard let self else { return }
                self.isConnected = connected
            }
        }
    }

    func cleanup() {
        if let handle = observerHandle {
            gameRef?.removeObserver(withHandle: handle)
        }
        if let handle = connectedHandle {
            Database.database().reference(withPath: ".info/connected").removeObserver(withHandle: handle)
        }
        if role == .host {
            if guestJoined {
                gameRef?.updateChildValues([
                    "hostId": NSNull(),
                    "hostName": NSNull(),
                    "hostMove": NSNull(),
                    "hostTaps": NSNull()
                ])
            } else {
                gameRef?.removeValue()
            }
        } else {
            gameRef?.updateChildValues([
                "guestId": NSNull(),
                "guestName": NSNull(),
                "guestMove": NSNull(),
                "guestTaps": NSNull()
            ])
        }
        gameRef = nil
        observerHandle = nil
        connectedHandle = nil
        onUpdate = nil
        onCreated = nil
    }
}
