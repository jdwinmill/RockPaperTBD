import Foundation

@Observable
final class CharacterManager {
    // MARK: - Testing Toggle
    // Set to true to unlock all packs without purchasing. Flip back to false for release.
    static let unlockAllPacks = true

    private(set) var loadout: CharacterLoadout
    private(set) var purchasedPackIds: Set<String>

    var catalogManager: CatalogManager?
    var imageCache: PackImageCache?

    private let loadoutKey = "characterLoadout"
    private let purchasedKey = "purchasedPacks"

    init() {
        if let data = UserDefaults.standard.data(forKey: "characterLoadout"),
           let saved = try? JSONDecoder().decode(CharacterLoadout.self, from: data) {
            self.loadout = saved
        } else {
            self.loadout = CatalogManager.defaultLoadout
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
        if let char = catalogManager?.character(byId: id) {
            return char
        }
        return CatalogManager.defaults.first { $0.slot == slot }!
    }

    func selectCharacter(_ character: GameCharacter, for slot: Move) {
        loadout.setCharacter(character.id, for: slot)
        saveLoadout()
    }

    func availableCharacters(for slot: Move) -> [GameCharacter] {
        let chars = catalogManager?.characters(for: slot) ?? CatalogManager.defaults.filter { $0.slot == slot }
        return chars.filter { char in
            Self.unlockAllPacks || char.packId == nil || purchasedPackIds.contains(char.packId!)
        }
    }

    // MARK: - Purchases

    func isPurchased(packId: String) -> Bool {
        Self.unlockAllPacks || purchasedPackIds.contains(packId)
    }

    func unlockPack(_ packId: String) {
        purchasedPackIds.insert(packId)
        savePurchases()
    }

    func resetAll() {
        loadout = CatalogManager.defaultLoadout
        purchasedPackIds = []
        UserDefaults.standard.removeObject(forKey: loadoutKey)
        UserDefaults.standard.removeObject(forKey: purchasedKey)
    }

    // MARK: - Display Helpers

    func display(for move: Move) -> (emoji: String, name: String, imageName: String?, packId: String?) {
        let char = character(for: move)
        return (char.emoji, char.name, char.imageName, char.packId)
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
