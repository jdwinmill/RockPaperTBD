import Foundation

enum Move: String, CaseIterable {
    case rock
    case paper
    case scissors

    var emoji: String {
        switch self {
        case .rock: return "🪨"
        case .paper: return "📄"
        case .scissors: return "✂️"
        }
    }

    var name: String {
        rawValue.capitalized
    }

    func beats(_ other: Move) -> Bool {
        switch (self, other) {
        case (.rock, .scissors): return true      // crushes
        case (.paper, .rock): return true          // covers
        case (.scissors, .paper): return true      // cuts
        default: return false
        }
    }

    func flavorText(against other: Move) -> String? {
        switch (self, other) {
        case (.rock, .scissors): return "Rock crushes Scissors!"
        case (.paper, .rock): return "Paper covers Rock!"
        case (.scissors, .paper): return "Scissors cuts Paper!"
        default: return nil
        }
    }
}

enum RoundResult {
    case player1Wins
    case player2Wins
    case tie

    var label: String {
        switch self {
        case .player1Wins: return "Player 1 Wins!"
        case .player2Wins: return "Player 2 Wins!"
        case .tie: return "It's a Tie!"
        }
    }
}

enum GameState: Equatable {
    case modeSelect
    case start
    case player1Select
    case transition
    case player2Select
    case countdown
    case reveal
    case gameOver
    case hostWaiting
    case joinGame
    case onlineSelect
    case onlineWaiting
}

enum PlayerRole {
    case host
    case guest
}
