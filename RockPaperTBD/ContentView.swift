import SwiftUI

struct ContentView: View {
    @State private var game = GameViewModel()

    var body: some View {
        ZStack {
            switch game.gameState {
            case .start:
                StartView(onStart: { bestOf in game.startGame(bestOf: bestOf) })
                    .transition(.opacity)

            case .player1Select:
                PlayerSelectView(
                    playerNumber: 1,
                    currentRound: game.currentRound,
                    player1Score: game.player1Score,
                    player2Score: game.player2Score,
                    onSelect: { move in
                        game.selectGesture(move, forPlayer: 1)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("p1select-\(game.currentRound)")

            case .transition:
                TransitionView(onReady: game.player2Ready)
                    .transition(.opacity)

            case .player2Select:
                PlayerSelectView(
                    playerNumber: 2,
                    currentRound: game.currentRound,
                    player1Score: game.player1Score,
                    player2Score: game.player2Score,
                    onSelect: { move in
                        game.selectGesture(move, forPlayer: 2)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("p2select-\(game.currentRound)")

            case .countdown:
                CountdownView(
                    onFinished: game.onCountdownFinished,
                    sound: game.sound
                )
                .transition(.opacity)

            case .reveal:
                if let p1 = game.player1Choice, let p2 = game.player2Choice,
                   let result = game.roundResult {
                    RevealView(
                        player1Choice: p1,
                        player2Choice: p2,
                        result: result,
                        player1Score: game.player1Score,
                        player2Score: game.player2Score,
                        currentRound: game.currentRound,
                        flavorText: game.flavorText,
                        isMatchOver: game.isMatchOver,
                        onNextRound: game.nextRound,
                        onReset: game.resetGame
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .gameOver:
                if let winner = game.matchWinner {
                    GameOverView(
                        winner: winner,
                        player1Score: game.player1Score,
                        player2Score: game.player2Score,
                        totalRounds: game.currentRound,
                        onPlayAgain: game.resetGame
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: game.gameState)
    }
}

#Preview {
    ContentView()
}
