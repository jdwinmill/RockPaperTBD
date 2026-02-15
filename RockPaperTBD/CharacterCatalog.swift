import Foundation

enum CharacterCatalog {
    // MARK: - Default Characters (always unlocked)

    static let defaultRock = GameCharacter(
        id: "default.rock", name: "Rock", emoji: "\u{1FAA8}",
        flavorText: "The classic crusher", slot: .rock, packId: nil
    )
    static let defaultPaper = GameCharacter(
        id: "default.paper", name: "Paper", emoji: "\u{1F4C4}",
        flavorText: "Covers all", slot: .paper, packId: nil
    )
    static let defaultScissors = GameCharacter(
        id: "default.scissors", name: "Scissors", emoji: "\u{2702}\u{FE0F}",
        flavorText: "Sharp and decisive", slot: .scissors, packId: nil
    )

    static let defaults: [GameCharacter] = [defaultRock, defaultPaper, defaultScissors]

    // MARK: - Samurai Pack

    static let samuraiRock = GameCharacter(
        id: "samurai.rock", name: "Katana", emoji: "\u{2694}\u{FE0F}",
        flavorText: "Slices through the competition", slot: .rock, packId: "samurai"
    )
    static let samuraiPaper = GameCharacter(
        id: "samurai.paper", name: "Shield", emoji: "\u{1F6E1}\u{FE0F}",
        flavorText: "An impenetrable defense", slot: .paper, packId: "samurai"
    )
    static let samuraiScissors = GameCharacter(
        id: "samurai.scissors", name: "Arrow", emoji: "\u{1F3F9}",
        flavorText: "Strikes from afar", slot: .scissors, packId: "samurai"
    )

    // MARK: - Space Pack

    static let spaceRock = GameCharacter(
        id: "space.rock", name: "Asteroid", emoji: "\u{1F311}",
        flavorText: "Hurtling through the cosmos", slot: .rock, packId: "space"
    )
    static let spacePaper = GameCharacter(
        id: "space.paper", name: "UFO", emoji: "\u{1F6F8}",
        flavorText: "Take me to your leader", slot: .paper, packId: "space"
    )
    static let spaceScissors = GameCharacter(
        id: "space.scissors", name: "Laser", emoji: "\u{26A1}",
        flavorText: "Pew pew pew!", slot: .scissors, packId: "space"
    )

    // MARK: - Animals Pack

    static let animalsRock = GameCharacter(
        id: "animals.rock", name: "Bear", emoji: "\u{1F43B}",
        flavorText: "Raw unstoppable power", slot: .rock, packId: "animals"
    )
    static let animalsPaper = GameCharacter(
        id: "animals.paper", name: "Eagle", emoji: "\u{1F985}",
        flavorText: "Soars above them all", slot: .paper, packId: "animals"
    )
    static let animalsScissors = GameCharacter(
        id: "animals.scissors", name: "Snake", emoji: "\u{1F40D}",
        flavorText: "Quick and venomous", slot: .scissors, packId: "animals"
    )

    // MARK: - All Characters

    static let allCharacters: [GameCharacter] = defaults + [
        samuraiRock, samuraiPaper, samuraiScissors,
        spaceRock, spacePaper, spaceScissors,
        animalsRock, animalsPaper, animalsScissors,
    ]

    // MARK: - Packs

    static let samuraiPack = CharacterPack(
        id: "samurai",
        name: "Samurai",
        description: "Ancient warriors of honor",
        productId: "com.outpostai.rockpapertbd.pack.samurai",
        characters: [samuraiRock, samuraiPaper, samuraiScissors]
    )

    static let spacePack = CharacterPack(
        id: "space",
        name: "Space",
        description: "Intergalactic combat awaits",
        productId: "com.outpostai.rockpapertbd.pack.space",
        characters: [spaceRock, spacePaper, spaceScissors]
    )

    static let animalsPack = CharacterPack(
        id: "animals",
        name: "Animals",
        description: "Nature's fiercest fighters",
        productId: "com.outpostai.rockpapertbd.pack.animals",
        characters: [animalsRock, animalsPaper, animalsScissors]
    )

    static let allPacks: [CharacterPack] = [samuraiPack, spacePack, animalsPack]

    // MARK: - Lookup

    static func character(byId id: String) -> GameCharacter? {
        allCharacters.first { $0.id == id }
    }

    static func characters(for slot: Move) -> [GameCharacter] {
        allCharacters.filter { $0.slot == slot }
    }

    static let defaultLoadout = CharacterLoadout(
        rockId: defaultRock.id,
        paperId: defaultPaper.id,
        scissorsId: defaultScissors.id
    )
}
