import SwiftUI

@Observable
final class GameViewModel {
    var gameState: GameState = .modeSelect
    var player1Choice: Move?
    var player2Choice: Move?
    var player1Score: Int = 0
    var player2Score: Int = 0
    var currentRound: Int = 1
    var roundResult: RoundResult?
    var flavorText: String?
    var bestOf: Int = 0
    var showDisconnectAlert: Bool = false

    // Online
    var session: GameSession?
    var isOnline: Bool { session != nil }

    var opponentId: String? {
        guard let data = session?.gameData else { return nil }
        if session?.role == .host {
            return data.guestId
        } else {
            return data.hostId
        }
    }

    var player1Name: String {
        if isOnline {
            return session?.gameData?.hostName ?? "Player 1"
        }
        return "Player 1"
    }

    var player2Name: String {
        if isOnline {
            return session?.gameData?.guestName ?? "Player 2"
        }
        return "Player 2"
    }

    var winsNeeded: Int {
        bestOf == 0 ? Int.max : (bestOf / 2) + 1
    }

    var matchWinner: RoundResult? {
        if player1Score >= winsNeeded { return .player1Wins }
        if player2Score >= winsNeeded { return .player2Wins }
        return nil
    }

    var isMatchOver: Bool { matchWinner != nil }

    var didLocalPlayerLose: Bool {
        guard isOnline, let winner = matchWinner, let role = session?.role else { return false }
        switch role {
        case .host: return winner == .player2Wins
        case .guest: return winner == .player1Wins
        }
    }

    let sound = SoundManager()

    // MARK: - Local Mode

    func selectGesture(_ gesture: Move, forPlayer player: Int) {
        sound.playTap()
        if player == 1 {
            player1Choice = gesture
            gameState = .transition
        } else {
            player2Choice = gesture
            gameState = .countdown
        }
    }

    func onCountdownFinished() {
        determineWinner()
        gameState = .reveal
    }

    func nextRound() {
        if isMatchOver {
            gameState = .gameOver
            return
        }
        let wasTie = roundResult == .tie
        player1Choice = nil
        player2Choice = nil
        roundResult = nil
        flavorText = nil
        if !wasTie {
            currentRound += 1
        }
        gameState = .player1Select
    }

    func resetGame() {
        session?.cleanup()
        session = nil
        player1Choice = nil
        player2Choice = nil
        player1Score = 0
        player2Score = 0
        currentRound = 1
        roundResult = nil
        flavorText = nil
        bestOf = 0
        gameState = .modeSelect
    }

    func resetToStart() {
        player1Choice = nil
        player2Choice = nil
        player1Score = 0
        player2Score = 0
        currentRound = 1
        roundResult = nil
        flavorText = nil
        bestOf = 0
        gameState = .start
    }

    func player2Ready() {
        gameState = .player2Select
    }

    func startGame(bestOf: Int) {
        player1Choice = nil
        player2Choice = nil
        player1Score = 0
        player2Score = 0
        currentRound = 1
        roundResult = nil
        flavorText = nil
        self.bestOf = bestOf
        gameState = .player1Select
    }

    // MARK: - Online Mode

    func hostGame(bestOf: Int, onCreated: (() -> Void)? = nil) {
        let session = GameSession()
        self.session = session
        self.bestOf = bestOf
        player1Score = 0
        player2Score = 0
        currentRound = 1
        player1Choice = nil
        player2Choice = nil
        roundResult = nil
        flavorText = nil
        session.onCreated = onCreated
        session.createGame(bestOf: bestOf)
        session.onUpdate = { [weak self] in self?.handleSessionUpdate() }
        gameState = .hostWaiting
    }

    func joinGame(code: String, completion: @escaping (Bool, String?) -> Void) {
        let session = GameSession()
        self.session = session
        session.joinGame(code: code) { [weak self] success in
            guard let self else { return }
            if success {
                session.onUpdate = { [weak self] in self?.handleSessionUpdate() }
                if let data = session.gameData {
                    self.bestOf = data.bestOf
                }
                self.player1Score = 0
                self.player2Score = 0
                self.currentRound = 1
                self.gameState = .onlineSelect
                completion(true, nil)
            } else {
                let error = session.error
                self.session = nil
                completion(false, error)
            }
        }
    }

    func submitOnlineMove(_ move: Move) {
        sound.playTap()
        session?.submitMove(move)
        if session?.role == .host {
            player1Choice = move
        } else {
            player2Choice = move
        }
        gameState = .onlineWaiting
    }

    func onlineNextRound() {
        if isMatchOver {
            gameState = .gameOver
            return
        }
        guard session?.role == .host else { return }
        let wasTie = roundResult == .tie
        player1Choice = nil
        player2Choice = nil
        roundResult = nil
        flavorText = nil
        if !wasTie {
            currentRound += 1
        }
        session?.clearRound(currentRound: currentRound)
        gameState = .onlineSelect
    }

    func handleSessionUpdate() {
        guard let session else { return }

        if session.opponentDisconnected {
            showDisconnectAlert = true
            return
        }

        guard let data = session.gameData else { return }

        switch gameState {
        case .hostWaiting:
            if data.guestId != nil {
                gameState = .onlineSelect
            }

        case .onlineWaiting:
            if data.bothMovesSubmitted {
                player1Choice = Move(rawValue: data.hostMove!)
                player2Choice = Move(rawValue: data.guestMove!)
                gameState = .countdown
            }

        case .onlineSelect:
            if session.role == .guest {
                currentRound = data.currentRound
            }

        case .reveal:
            // Guest: detect host starting next round (moves cleared)
            if session.role == .guest && data.hostMove == nil && data.guestMove == nil {
                player1Choice = nil
                player2Choice = nil
                roundResult = nil
                flavorText = nil
                currentRound = data.currentRound
                gameState = .onlineSelect
            }

        default:
            break
        }
    }

    private func determineWinner() {
        guard let p1 = player1Choice, let p2 = player2Choice else { return }

        if p1 == p2 {
            roundResult = .tie
            flavorText = nil
            sound.playTie()
        } else if p1.beats(p2) {
            roundResult = .player1Wins
            player1Score += 1
            flavorText = p1.flavorText(against: p2)
            if isOnline && session?.role == .guest {
                sound.playLose()
            } else {
                sound.playWin()
            }
        } else {
            roundResult = .player2Wins
            player2Score += 1
            flavorText = p2.flavorText(against: p1)
            if isOnline && session?.role == .host {
                sound.playLose()
            } else {
                sound.playWin()
            }
        }
    }
}
