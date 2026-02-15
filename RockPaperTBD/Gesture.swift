import Foundation

enum Move: String, CaseIterable, Codable {
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

    func display(using manager: CharacterManager?) -> (emoji: String, name: String) {
        guard let manager else { return (emoji, name) }
        return manager.display(for: self)
    }

    func flavorText(against other: Move, myCharacter: GameCharacter?, opponentCharacter: GameCharacter?) -> String? {
        guard let mine = myCharacter, let theirs = opponentCharacter else {
            return flavorText(against: other)
        }
        guard self.beats(other) else { return nil }
        return "\(mine.name) defeats \(theirs.name)!"
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
    case countdown
    case reveal
    case gameOver
    case hostWaiting
    case joinGame
    case onlineSelect
    case onlineWaiting
    case tapBattle
}

enum PlayerRole {
    case host
    case guest
}

enum TapBattleMode: String {
    case tiesOnly
    case always
}

enum BattleType {
    case tap
    case swipe

    static func determine(roomCode: String, round: Int) -> BattleType {
        let codeSum = roomCode.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (codeSum + round) % 2 == 0 ? .tap : .swipe
    }
}

enum GameConfig {
    static let bestOfOptions: [(label: String, value: Int)] = [
        ("Best of 3", 3),
        ("Best of 5", 5),
        ("Best of 7", 7),
        ("Endless", 0),
    ]

    static func cpuTapCount(for battleType: BattleType) -> Int {
        switch battleType {
        case .tap:   return Int.random(in: 25...45)
        case .swipe: return Int.random(in: 10...22)
        }
    }
}
