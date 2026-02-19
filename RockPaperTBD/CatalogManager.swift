import Foundation
import FirebaseDatabase

@Observable
final class CatalogManager {
    private(set) var packs: [CharacterPack] = []
    private(set) var allCharacters: [GameCharacter] = []
    private(set) var isLoaded = false

    private var handle: UInt?

    // MARK: - Defaults (always available offline)

    static let defaultRock = GameCharacter(
        id: "default.rock", name: "Rock", emoji: "\u{1FAA8}",
        flavorText: "The classic crusher", slot: .rock, packId: nil, imageName: nil
    )
    static let defaultPaper = GameCharacter(
        id: "default.paper", name: "Paper", emoji: "\u{1F4C4}",
        flavorText: "Covers all", slot: .paper, packId: nil, imageName: nil
    )
    static let defaultScissors = GameCharacter(
        id: "default.scissors", name: "Scissors", emoji: "\u{2702}\u{FE0F}",
        flavorText: "Sharp and decisive", slot: .scissors, packId: nil, imageName: nil
    )

    static let defaults: [GameCharacter] = [defaultRock, defaultPaper, defaultScissors]

    static let defaultLoadout = CharacterLoadout(
        rockId: defaultRock.id,
        paperId: defaultPaper.id,
        scissorsId: defaultScissors.id
    )

    // MARK: - Observe

    func observeCatalog() {
        let ref = Database.database().reference().child(FirebasePath.catalog)
        handle = ref.observe(.value) { [weak self] snapshot in
            guard let self else { return }
            self.parseCatalog(snapshot)
            self.isLoaded = true
        }
    }

    func stopObserving() {
        guard let handle else { return }
        Database.database().reference().child(FirebasePath.catalog).removeObserver(withHandle: handle)
        self.handle = nil
    }

    // MARK: - Lookup

    func character(byId id: String) -> GameCharacter? {
        Self.defaults.first(where: { $0.id == id }) ??
        allCharacters.first(where: { $0.id == id })
    }

    func characters(for slot: Move) -> [GameCharacter] {
        (Self.defaults + allCharacters).filter { $0.slot == slot }
    }

    func storePacks(purchasedIds: Set<String>) -> [CharacterPack] {
        packs.filter { $0.active || purchasedIds.contains($0.id) }
    }

    // MARK: - Parse

    private func parseCatalog(_ snapshot: DataSnapshot) {
        var parsedPacks: [CharacterPack] = []
        var parsedCharacters: [GameCharacter] = []

        for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
            guard let dict = child.value as? [String: Any] else { continue }
            let packId = child.key

            let name = dict["name"] as? String ?? packId
            let description = dict["description"] as? String ?? ""
            let productId = dict["productId"] as? String ?? ""
            let active = dict["active"] as? Bool ?? true

            var characters: [GameCharacter] = []
            if let charsDict = dict["characters"] as? [String: [String: Any]] {
                for (slot, charData) in charsDict {
                    guard let move = Move(rawValue: slot) else { continue }
                    let charId = charData["id"] as? String ?? "\(packId).\(slot)"
                    let charName = charData["name"] as? String ?? slot
                    let emoji = charData["emoji"] as? String ?? "?"
                    let flavorText = charData["flavorText"] as? String ?? ""
                    let imageName = charData["imageName"] as? String

                    let character = GameCharacter(
                        id: charId, name: charName, emoji: emoji,
                        flavorText: flavorText, slot: move,
                        packId: packId, imageName: imageName
                    )
                    characters.append(character)
                    parsedCharacters.append(character)
                }
            }

            let pack = CharacterPack(
                id: packId, name: name, description: description,
                productId: productId, active: active,
                characters: characters.sorted { $0.slot.rawValue < $1.slot.rawValue }
            )
            parsedPacks.append(pack)
        }

        packs = parsedPacks.sorted { $0.name < $1.name }
        allCharacters = parsedCharacters
    }
}
