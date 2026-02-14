import SwiftUI

@Observable
final class GameViewModel {
    var gameState: GameState = .start
    var player1Choice: Move?
    var player2Choice: Move?
    var player1Score: Int = 0
    var player2Score: Int = 0
    var currentRound: Int = 1
    var roundResult: RoundResult?
    var flavorText: String?
    var bestOf: Int = 0

    var winsNeeded: Int {
        bestOf == 0 ? Int.max : (bestOf / 2) + 1
    }

    var matchWinner: RoundResult? {
        if player1Score >= winsNeeded { return .player1Wins }
        if player2Score >= winsNeeded { return .player2Wins }
        return nil
    }

    var isMatchOver: Bool { matchWinner != nil }

    let sound = SoundManager()

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
        resetGame()
        self.bestOf = bestOf
        gameState = .player1Select
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
            sound.playWin()
        } else {
            roundResult = .player2Wins
            player2Score += 1
            flavorText = p2.flavorText(against: p1)
            sound.playWin()
        }
    }
}
