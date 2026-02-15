import Foundation

struct GameCharacter: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let emoji: String
    let flavorText: String
    let slot: Move
    let packId: String?
    let imageName: String?
}

struct CharacterPack: Identifiable {
    let id: String
    let name: String
    let description: String
    let productId: String
    let characters: [GameCharacter]
}

struct CharacterLoadout: Codable {
    var rockId: String
    var paperId: String
    var scissorsId: String

    func characterId(for slot: Move) -> String {
        switch slot {
        case .rock: return rockId
        case .paper: return paperId
        case .scissors: return scissorsId
        }
    }

    mutating func setCharacter(_ id: String, for slot: Move) {
        switch slot {
        case .rock: rockId = id
        case .paper: paperId = id
        case .scissors: scissorsId = id
        }
    }
}
