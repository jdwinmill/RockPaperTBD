import Foundation

@Observable
final class CharacterManager {
    private(set) var loadout: CharacterLoadout
    private(set) var purchasedPackIds: Set<String>

    private let loadoutKey = "characterLoadout"
    private let purchasedKey = "purchasedPacks"

    init() {
        if let data = UserDefaults.standard.data(forKey: "characterLoadout"),
           let saved = try? JSONDecoder().decode(CharacterLoadout.self, from: data) {
            self.loadout = saved
        } else {
            self.loadout = CharacterCatalog.defaultLoadout
        }

        if let ids = UserDefaults.standard.stringArray(forKey: "purchasedPacks") {
            self.purchasedPackIds = Set(ids)
        } else {
            self.purchasedPackIds = []
        }
    }

    // MARK: - Character Selection

    func character(for slot: Move) -> GameCharacter {
        let id = loadout.characterId(for: slot)
        return CharacterCatalog.character(byId: id) ?? CharacterCatalog.defaults.first { $0.slot == slot }!
    }

    func selectCharacter(_ character: GameCharacter, for slot: Move) {
        loadout.setCharacter(character.id, for: slot)
        saveLoadout()
    }

    func availableCharacters(for slot: Move) -> [GameCharacter] {
        CharacterCatalog.characters(for: slot).filter { char in
            char.packId == nil || purchasedPackIds.contains(char.packId!)
        }
    }

    // MARK: - Purchases

    func isPurchased(packId: String) -> Bool {
        purchasedPackIds.contains(packId)
    }

    func unlockPack(_ packId: String) {
        purchasedPackIds.insert(packId)
        savePurchases()
    }

    // MARK: - Display Helpers

    func display(for move: Move) -> (emoji: String, name: String, imageName: String?) {
        let char = character(for: move)
        return (char.emoji, char.name, char.imageName)
    }

    // MARK: - Persistence

    private func saveLoadout() {
        if let data = try? JSONEncoder().encode(loadout) {
            UserDefaults.standard.set(data, forKey: loadoutKey)
        }
    }

    private func savePurchases() {
        UserDefaults.standard.set(Array(purchasedPackIds), forKey: purchasedKey)
    }
}
