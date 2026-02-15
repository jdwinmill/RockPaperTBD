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

    // Tap Battle
    var player1Taps: Int = 0
    var player2Taps: Int = 0
    var rpsAdvantage: RoundResult?
    var tapBattleSubmitted: Bool = false
    var tapBattleMode: TapBattleMode = .tiesOnly
    var battleType: BattleType = .tap

    // VS Computer
    var isVsComputer: Bool = false

    // Online
    var session: (any GameSessionProtocol)?
    var isOnline: Bool { session != nil }
    var makeSession: () -> any GameSessionProtocol = { GameSession() }

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
        if isVsComputer { return "CPU" }
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

    var shouldShowBattleWarning: Bool {
        guard isOnline || isVsComputer else { return false }
        if tapBattleMode == .always { return true }
        // tiesOnly: show warning only if it's a tie
        guard let p1 = player1Choice, let p2 = player2Choice else { return false }
        return p1 == p2
    }

    var didLocalPlayerLose: Bool {
        guard let winner = matchWinner else { return false }
        if isVsComputer { return winner == .player2Wins }
        guard isOnline, let role = session?.role else { return false }
        switch role {
        case .host: return winner == .player2Wins
        case .guest: return winner == .player1Wins
        }
    }

    let sound: any SoundPlayable

    init(sound: any SoundPlayable = SoundManager()) {
        self.sound = sound
    }

    // MARK: - Local Mode

    func selectGesture(_ gesture: Move) {
        sound.playTap()
        player1Choice = gesture
        if isVsComputer {
            player2Choice = Move.allCases.randomElement()!
        }
        gameState = .countdown
    }

    func onCountdownFinished() {
        if isOnline || isVsComputer {
            let rps = computeRpsResult()
            rpsAdvantage = rps

            let shouldBattle = tapBattleMode == .always || rps == .tie
            if shouldBattle {
                if isOnline {
                    battleType = BattleType.determine(
                        roomCode: session?.roomCode ?? "",
                        round: currentRound
                    )
                } else {
                    battleType = Bool.random() ? .tap : .swipe
                }
                gameState = .tapBattle
            } else {
                determineWinner()
                gameState = .reveal
            }
        } else {
            determineWinner()
            gameState = .reveal
        }
    }

    func nextRound() {
        if isMatchOver {
            gameState = .gameOver
            return
        }
        advanceToNextRound()
        gameState = .player1Select
    }

    func resetGame() {
        session?.cleanup()
        session = nil
        isVsComputer = false
        clearGameState()
        gameState = .modeSelect
    }

    func resetToStart() {
        isVsComputer = false
        clearGameState()
        gameState = .start
    }

    func startGame(bestOf: Int, tapBattleMode: TapBattleMode = .tiesOnly) {
        clearGameState()
        self.bestOf = bestOf
        self.tapBattleMode = tapBattleMode
        isVsComputer = true
        gameState = .player1Select
    }

    private func clearGameState() {
        player1Choice = nil
        player2Choice = nil
        player1Score = 0
        player2Score = 0
        currentRound = 1
        roundResult = nil
        flavorText = nil
        bestOf = 0
        player1Taps = 0
        player2Taps = 0
        rpsAdvantage = nil
        tapBattleSubmitted = false
        tapBattleMode = .tiesOnly
        battleType = .tap
    }

    private func advanceToNextRound() {
        let wasTie = roundResult == .tie
        player1Choice = nil
        player2Choice = nil
        roundResult = nil
        flavorText = nil
        player1Taps = 0
        player2Taps = 0
        rpsAdvantage = nil
        tapBattleSubmitted = false
        battleType = .tap
        if !wasTie {
            currentRound += 1
        }
    }

    // MARK: - Online Mode

    func hostGame(bestOf: Int, tapBattleMode: TapBattleMode = .tiesOnly, onCreated: (() -> Void)? = nil) {
        let session = makeSession()
        self.session = session
        clearGameState()
        self.bestOf = bestOf
        self.tapBattleMode = tapBattleMode
        session.onCreated = onCreated
        session.createGame(bestOf: bestOf, tapBattleMode: tapBattleMode)
        session.onUpdate = { [weak self] in self?.handleSessionUpdate() }
        gameState = .hostWaiting
    }

    func joinGame(code: String, completion: @escaping (Bool, String?) -> Void) {
        let session = makeSession()
        self.session = session
        session.joinGame(code: code) { [weak self] success in
            guard let self else { return }
            if success {
                session.onUpdate = { [weak self] in self?.handleSessionUpdate() }
                if let data = session.gameData {
                    self.bestOf = data.bestOf
                    self.tapBattleMode = TapBattleMode(rawValue: data.tapBattleMode ?? "tiesOnly") ?? .tiesOnly
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
        advanceToNextRound()
        session?.clearRound(currentRound: currentRound)
        gameState = .onlineSelect
    }

    // MARK: - Tap Battle

    func registerTap() {
        guard gameState == .tapBattle, !tapBattleSubmitted else { return }
        if isVsComputer || session?.role == .host {
            player1Taps += 1
        } else {
            player2Taps += 1
        }
        let localTaps = isVsComputer ? player1Taps : (session?.role == .host ? player1Taps : player2Taps)
        let intensity = min(1.0, Double(localTaps) / 40.0)
        sound.playBattleTap(intensity: intensity)
    }

    func submitTapCount() {
        guard !tapBattleSubmitted else { return }
        tapBattleSubmitted = true
        if isVsComputer {
            player2Taps = GameConfig.cpuTapCount(for: battleType)
            resolveTapBattleLocally()
        } else {
            let count = session?.role == .host ? player1Taps : player2Taps
            session?.submitTapCount(count)
        }
    }

    func onTapBattleResolved() {
        guard let data = session?.gameData,
              let p1 = player1Choice, let p2 = player2Choice,
              let hostTaps = data.hostTaps, let guestTaps = data.guestTaps else { return }

        player1Taps = hostTaps
        player2Taps = guestTaps

        let headStart = 10
        let p1Effective = hostTaps + (rpsAdvantage == .player1Wins ? headStart : 0)
        let p2Effective = guestTaps + (rpsAdvantage == .player2Wins ? headStart : 0)

        if p1Effective > p2Effective {
            roundResult = .player1Wins
            player1Score += 1
            flavorText = p1.flavorText(against: p2)
        } else if p2Effective > p1Effective {
            roundResult = .player2Wins
            player2Score += 1
            flavorText = p2.flavorText(against: p1)
        } else {
            // Equal effective taps — RPS advantage breaks the tie
            if let advantage = rpsAdvantage, advantage != .tie {
                roundResult = advantage
                if advantage == .player1Wins {
                    player1Score += 1
                    flavorText = p1.flavorText(against: p2)
                } else {
                    player2Score += 1
                    flavorText = p2.flavorText(against: p1)
                }
            } else {
                roundResult = .tie
                flavorText = nil
            }
        }

        // Play appropriate sound
        if roundResult == .tie {
            sound.playTie()
        } else if (roundResult == .player1Wins && session?.role == .host) ||
                  (roundResult == .player2Wins && session?.role == .guest) {
            sound.playWin()
        } else {
            sound.playLose()
        }

        gameState = .reveal
    }

    private func resolveTapBattleLocally() {
        guard let p1 = player1Choice, let p2 = player2Choice else { return }

        let headStart = 10
        let p1Effective = player1Taps + (rpsAdvantage == .player1Wins ? headStart : 0)
        let p2Effective = player2Taps + (rpsAdvantage == .player2Wins ? headStart : 0)

        if p1Effective > p2Effective {
            roundResult = .player1Wins
            player1Score += 1
            flavorText = p1.flavorText(against: p2)
        } else if p2Effective > p1Effective {
            roundResult = .player2Wins
            player2Score += 1
            flavorText = p2.flavorText(against: p1)
        } else {
            if let advantage = rpsAdvantage, advantage != .tie {
                roundResult = advantage
                if advantage == .player1Wins {
                    player1Score += 1
                    flavorText = p1.flavorText(against: p2)
                } else {
                    player2Score += 1
                    flavorText = p2.flavorText(against: p1)
                }
            } else {
                roundResult = .tie
                flavorText = nil
            }
        }

        if roundResult == .tie {
            sound.playTie()
        } else if roundResult == .player1Wins {
            sound.playWin()
        } else {
            sound.playLose()
        }

        gameState = .reveal
    }

    private func computeRpsResult() -> RoundResult {
        guard let p1 = player1Choice, let p2 = player2Choice else { return .tie }
        if p1 == p2 { return .tie }
        return p1.beats(p2) ? .player1Wins : .player2Wins
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

        case .tapBattle:
            if data.bothTapsSubmitted {
                onTapBattleResolved()
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
                player1Taps = 0
                player2Taps = 0
                rpsAdvantage = nil
                tapBattleSubmitted = false
                battleType = .tap
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
            if isVsComputer || (isOnline && session?.role == .host) {
                sound.playLose()
            } else {
                sound.playWin()
            }
        }
    }
}
