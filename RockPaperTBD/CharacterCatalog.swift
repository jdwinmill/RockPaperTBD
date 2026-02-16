import Foundation

enum CharacterCatalog {
    // MARK: - Default Characters (always unlocked)

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

    // MARK: - Samurai Pack

    static let samuraiRock = GameCharacter(
        id: "samurai.rock", name: "Katana", emoji: "\u{2694}\u{FE0F}",
        flavorText: "Slices through the competition", slot: .rock, packId: "samurai", imageName: "samurai_katana"
    )
    static let samuraiPaper = GameCharacter(
        id: "samurai.paper", name: "Shield", emoji: "\u{1F6E1}\u{FE0F}",
        flavorText: "An impenetrable defense", slot: .paper, packId: "samurai", imageName: "samurai_shield"
    )
    static let samuraiScissors = GameCharacter(
        id: "samurai.scissors", name: "Arrow", emoji: "\u{1F3F9}",
        flavorText: "Strikes from afar", slot: .scissors, packId: "samurai", imageName: "samurai_arrow"
    )

    // MARK: - Space Pack

    static let spaceRock = GameCharacter(
        id: "space.rock", name: "Asteroid", emoji: "\u{1F311}",
        flavorText: "Hurtling through the cosmos", slot: .rock, packId: "space", imageName: "space_asteroid"
    )
    static let spacePaper = GameCharacter(
        id: "space.paper", name: "UFO", emoji: "\u{1F6F8}",
        flavorText: "Take me to your leader", slot: .paper, packId: "space", imageName: "space_ufo"
    )
    static let spaceScissors = GameCharacter(
        id: "space.scissors", name: "Laser", emoji: "\u{26A1}",
        flavorText: "Pew pew pew!", slot: .scissors, packId: "space", imageName: "space_laser"
    )

    // MARK: - Animals Pack

    static let animalsRock = GameCharacter(
        id: "animals.rock", name: "Bear", emoji: "\u{1F43B}",
        flavorText: "Raw unstoppable power", slot: .rock, packId: "animals", imageName: "animals_bear"
    )
    static let animalsPaper = GameCharacter(
        id: "animals.paper", name: "Eagle", emoji: "\u{1F985}",
        flavorText: "Soars above them all", slot: .paper, packId: "animals", imageName: "animals_eagle"
    )
    static let animalsScissors = GameCharacter(
        id: "animals.scissors", name: "Snake", emoji: "\u{1F40D}",
        flavorText: "Quick and venomous", slot: .scissors, packId: "animals", imageName: "animals_snake"
    )

    // MARK: - Mythical Pack

    static let mythicalRock = GameCharacter(
        id: "mythical.rock", name: "Kraken", emoji: "🐙",
        flavorText: "Dragging ships to the deep", slot: .rock, packId: "mythical", imageName: "mythical_kraken"
    )
    static let mythicalPaper = GameCharacter(
        id: "mythical.paper", name: "Phoenix", emoji: "🔥",
        flavorText: "Reborn from the ashes", slot: .paper, packId: "mythical", imageName: "mythical_phoenix"
    )
    static let mythicalScissors = GameCharacter(
        id: "mythical.scissors", name: "Basilisk", emoji: "🐍",
        flavorText: "One glance is all it takes", slot: .scissors, packId: "mythical", imageName: "mythical_basilisk"
    )

    // MARK: - All Characters

    static let allCharacters: [GameCharacter] = defaults + [
        samuraiRock, samuraiPaper, samuraiScissors,
        spaceRock, spacePaper, spaceScissors,
        animalsRock, animalsPaper, animalsScissors,
        mythicalRock, mythicalPaper, mythicalScissors,
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

    static let mythicalPack = CharacterPack(
        id: "mythical",
        name: "Mythical",
        description: "Legendary creatures of myth",
        productId: "com.outpostai.rockpapertbd.pack.mythical",
        characters: [mythicalRock, mythicalPaper, mythicalScissors]
    )

    static let allPacks: [CharacterPack] = [samuraiPack, spacePack, animalsPack, mythicalPack]

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
