//
//  RockPaperTBDTests.swift
//  RockPaperTBDTests
//
//  Created by Jacob Winmill on 2/11/26.
//

import Foundation
import Testing
@testable import RockPaperTBD

// MARK: - Move Tests

struct MoveTests {
    @Test func rockBeatsScissors() {
        #expect(Move.rock.beats(.scissors))
    }

    @Test func paperBeatsRock() {
        #expect(Move.paper.beats(.rock))
    }

    @Test func scissorsBeatsPaper() {
        #expect(Move.scissors.beats(.paper))
    }

    @Test func rockDoesNotBeatPaper() {
        #expect(!Move.rock.beats(.paper))
    }

    @Test func sameMovesDoNotBeat() {
        for move in Move.allCases {
            #expect(!move.beats(move))
        }
    }

    @Test func flavorTextExists() {
        #expect(Move.rock.flavorText(against: .scissors) != nil)
        #expect(Move.paper.flavorText(against: .rock) != nil)
        #expect(Move.scissors.flavorText(against: .paper) != nil)
    }

    @Test func flavorTextNilForLoss() {
        #expect(Move.rock.flavorText(against: .paper) == nil)
    }

    @Test func flavorTextNilForTie() {
        #expect(Move.rock.flavorText(against: .rock) == nil)
    }

    @Test func emojiIsNotEmpty() {
        for move in Move.allCases {
            #expect(!move.emoji.isEmpty)
        }
    }

    @Test func nameIsCapitalized() {
        #expect(Move.rock.name == "Rock")
        #expect(Move.paper.name == "Paper")
        #expect(Move.scissors.name == "Scissors")
    }
}

// MARK: - RoundResult Tests

struct RoundResultTests {
    @Test func labelsAreNotEmpty() {
        let results: [RoundResult] = [.player1Wins, .player2Wins, .tie]
        for result in results {
            #expect(!result.label.isEmpty)
        }
    }
}

// MARK: - RoomCode Tests

struct RoomCodeTests {
    @Test func generatesCorrectLength() {
        let code = RoomCode.generate()
        #expect(code.count == 4)
    }

    @Test func containsOnlyAllowedCharacters() {
        let allowed = Set("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        for _ in 0..<100 {
            let code = RoomCode.generate()
            for char in code {
                #expect(allowed.contains(char), "Unexpected character: \(char)")
            }
        }
    }

    @Test func excludesAmbiguousCharacters() {
        let ambiguous: Set<Character> = ["0", "O", "1", "I"]
        for _ in 0..<200 {
            let code = RoomCode.generate()
            for char in code {
                #expect(!ambiguous.contains(char))
            }
        }
    }
}

// MARK: - OnlineGameData Tests

struct OnlineGameDataTests {
    @Test func bothMovesSubmitted() {
        let data = OnlineGameData(
            hostId: "abc",
            guestId: "def",
            bestOf: 3,
            hostMove: "rock",
            guestMove: "paper",
            currentRound: 1,
            timestamp: 0
        )
        #expect(data.bothMovesSubmitted)
    }

    @Test func notBothMovesWhenMissing() {
        let data = OnlineGameData(
            hostId: "abc",
            guestId: "def",
            bestOf: 3,
            hostMove: "rock",
            guestMove: nil,
            currentRound: 1,
            timestamp: 0
        )
        #expect(!data.bothMovesSubmitted)
    }
}

// MARK: - PlayerIdentity Tests

struct PlayerIdentityTests {
    @Test func idIsConsistent() {
        let id1 = PlayerIdentity.id
        let id2 = PlayerIdentity.id
        #expect(id1 == id2)
    }

    @Test func idIsNotEmpty() {
        #expect(!PlayerIdentity.id.isEmpty)
    }
}

// MARK: - GameViewModel Tests (Local Mode)

@MainActor
struct GameViewModelLocalTests {
    private func makeVM() -> GameViewModel {
        GameViewModel(sound: MockSoundManager())
    }

    @Test func initialState() {
        let vm = makeVM()
        #expect(vm.gameState == .modeSelect)
        #expect(vm.player1Score == 0)
        #expect(vm.player2Score == 0)
        #expect(vm.currentRound == 1)
        #expect(vm.session == nil)
        #expect(!vm.isOnline)
    }

    @Test func startGameSetsState() {
        let vm = makeVM()
        vm.startGame(bestOf: 5)
        #expect(vm.bestOf == 5)
        #expect(vm.gameState == .player1Select)
    }

    @Test func winsNeededCalculation() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        #expect(vm.winsNeeded == 2)

        vm.startGame(bestOf: 5)
        #expect(vm.winsNeeded == 3)

        vm.startGame(bestOf: 7)
        #expect(vm.winsNeeded == 4)
    }

    @Test func endlessModeWinsNeeded() {
        let vm = makeVM()
        vm.startGame(bestOf: 0)
        #expect(vm.winsNeeded == Int.max)
        #expect(!vm.isMatchOver)
    }

    @Test func selectGestureSetsChoiceAndGoesToCountdown() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.selectGesture(.rock)
        #expect(vm.player1Choice == .rock)
        #expect(vm.player2Choice != nil) // CPU picks randomly
        #expect(vm.gameState == .countdown)
    }

    @Test func countdownFinishedDeterminesWinner() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.gameState = .countdown
        vm.onCountdownFinished()
        #expect(vm.roundResult == .player1Wins)
        #expect(vm.player1Score == 1)
        #expect(vm.gameState == .reveal)
    }

    @Test func tieDoesNotAdvanceRound() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.isVsComputer = false // bypass tap battle for pure logic test
        vm.player1Choice = .rock
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .tie)
        let roundBefore = vm.currentRound
        vm.nextRound()
        #expect(vm.currentRound == roundBefore) // tie = same round
    }

    @Test func winAdvancesRound() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        let roundBefore = vm.currentRound
        vm.nextRound()
        #expect(vm.currentRound == roundBefore + 1)
    }

    @Test func matchOverDetected() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        // Win round 1
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        #expect(!vm.isMatchOver)
        vm.nextRound()
        // Win round 2
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        #expect(vm.isMatchOver)
        #expect(vm.matchWinner == .player1Wins)
    }

    @Test func nextRoundGoesToGameOverWhenMatchDone() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        vm.nextRound()
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        vm.nextRound()
        #expect(vm.gameState == .gameOver)
    }

    @Test func resetGameClearsEverything() {
        let vm = makeVM()
        vm.startGame(bestOf: 5)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        vm.resetGame()
        #expect(vm.gameState == .modeSelect)
        #expect(vm.player1Score == 0)
        #expect(vm.player2Score == 0)
        #expect(vm.currentRound == 1)
        #expect(vm.player1Choice == nil)
        #expect(vm.player2Choice == nil)
        #expect(vm.roundResult == nil)
    }

    @Test func resetToStartGoesToStart() {
        let vm = makeVM()
        vm.startGame(bestOf: 5)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        vm.resetToStart()
        #expect(vm.gameState == .start)
        #expect(vm.player1Score == 0)
        #expect(vm.bestOf == 0)
    }

    @Test func player2WinsScoring() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .scissors
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .player2Wins)
        #expect(vm.player2Score == 1)
        #expect(vm.player1Score == 0)
    }

    @Test func flavorTextSetOnWin() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        #expect(vm.flavorText != nil)
    }

    @Test func flavorTextNilOnTie() {
        let vm = makeVM()
        vm.startGame(bestOf: 3)
        vm.isVsComputer = false // bypass tap battle for pure logic test
        vm.player1Choice = .rock
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .tie)
        #expect(vm.flavorText == nil)
    }
}

// MARK: - CodeCharset Tests

struct CodeCharsetTests {
    @Test func generatesCorrectLength() {
        let code3 = CodeCharset.generate(length: 3)
        #expect(code3.count == 3)
        let code8 = CodeCharset.generate(length: 8)
        #expect(code8.count == 8)
    }

    @Test func containsOnlyAllowedCharacters() {
        let allowed = Set(CodeCharset.characters)
        for _ in 0..<100 {
            let code = CodeCharset.generate(length: 10)
            for char in code {
                #expect(allowed.contains(char), "Unexpected character: \(char)")
            }
        }
    }
}

// MARK: - FriendCode Tests

struct FriendCodeTests {
    @Test func generatesCorrectLength() {
        let code = FriendCode.generate()
        #expect(code.count == 6)
    }

    @Test func containsOnlyAllowedCharacters() {
        let allowed = Set(CodeCharset.characters)
        for _ in 0..<100 {
            let code = FriendCode.generate()
            for char in code {
                #expect(allowed.contains(char), "Unexpected character: \(char)")
            }
        }
    }
}

// MARK: - DisplayName Tests

struct DisplayNameTests {
    @Test func saveAndRetrieve() {
        let testName = "TestPlayer_\(UUID().uuidString.prefix(4))"
        DisplayName.save(testName)
        #expect(DisplayName.saved == testName)
    }
}

// MARK: - PlayerStats Tests

struct PlayerStatsTests {
    @Test func matchesPlayed() {
        let stats = PlayerStats(playerId: "a", displayName: "Test", wins: 5, losses: 3)
        #expect(stats.matchesPlayed == 8)
    }

    @Test func winPercentage() {
        let stats = PlayerStats(playerId: "a", displayName: "Test", wins: 3, losses: 1)
        #expect(stats.winPercentage == 0.75)
    }

    @Test func winPercentageZeroMatches() {
        let stats = PlayerStats(playerId: "a", displayName: "Test", wins: 0, losses: 0)
        #expect(stats.winPercentage == 0)
    }

    @Test func identifiable() {
        let stats = PlayerStats(playerId: "abc", displayName: "Test", wins: 0, losses: 0)
        #expect(stats.id == "abc")
    }
}

// MARK: - GameInvite Tests

struct GameInviteTests {
    @Test func freshInviteIsNotStale() {
        let invite = GameInvite(
            senderId: "abc",
            senderName: "Test",
            roomCode: "ABCD",
            bestOf: 3,
            timestamp: Date().timeIntervalSince1970 * 1000
        )
        #expect(!invite.isStale)
    }

    @Test func oldInviteIsStale() {
        let oldTimestamp = (Date().timeIntervalSince1970 - 600) * 1000
        let invite = GameInvite(
            senderId: "abc",
            senderName: "Test",
            roomCode: "ABCD",
            bestOf: 3,
            timestamp: oldTimestamp
        )
        #expect(invite.isStale)
    }
}

// MARK: - GameConfig Tests

struct GameConfigTests {
    @Test func optionsAreValid() {
        #expect(!GameConfig.bestOfOptions.isEmpty)
        for option in GameConfig.bestOfOptions {
            #expect(!option.label.isEmpty)
            #expect(option.value >= 0)
        }
    }

    @Test func containsExpectedValues() {
        let values = GameConfig.bestOfOptions.map(\.value)
        #expect(values.contains(3))
        #expect(values.contains(5))
        #expect(values.contains(7))
        #expect(values.contains(0))
    }
}

// MARK: - GameViewModel Online Mode Tests

@MainActor
struct GameViewModelOnlineTests {
    private func makeVM() -> (GameViewModel, MockGameSession, MockSoundManager) {
        let sound = MockSoundManager()
        let vm = GameViewModel(sound: sound)
        let session = MockGameSession()
        vm.makeSession = { session }
        return (vm, session, sound)
    }

    @Test func hostGameSetsStateToHostWaiting() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        #expect(vm.gameState == .hostWaiting)
        #expect(session.createGameCalled)
        #expect(session.createGameBestOf == 3)
        #expect(vm.session != nil)
    }

    @Test func submitOnlineMoveAsHostSetsPlayer1Choice() {
        let (vm, _, _) = makeVM()
        vm.hostGame(bestOf: 3)
        vm.gameState = .onlineSelect
        vm.submitOnlineMove(.rock)
        #expect(vm.player1Choice == .rock)
        #expect(vm.gameState == .onlineWaiting)
    }

    @Test func submitOnlineMoveAsGuestSetsPlayer2Choice() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        session.role = .guest
        vm.gameState = .onlineSelect
        vm.submitOnlineMove(.paper)
        #expect(vm.player2Choice == .paper)
        #expect(vm.gameState == .onlineWaiting)
    }

    @Test func handleSessionUpdateGuestJoinedGoesToOnlineSelect() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        #expect(vm.gameState == .hostWaiting)
        session.gameData = OnlineGameData(
            hostId: "host", guestId: "guest", bestOf: 3,
            currentRound: 1, timestamp: 0
        )
        vm.handleSessionUpdate()
        #expect(vm.gameState == .onlineSelect)
    }

    @Test func handleSessionUpdateBothMovesGoesToCountdown() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        vm.gameState = .onlineWaiting
        session.gameData = OnlineGameData(
            hostId: "host", guestId: "guest", bestOf: 3,
            hostMove: "rock", guestMove: "scissors",
            currentRound: 1, timestamp: 0
        )
        vm.handleSessionUpdate()
        #expect(vm.gameState == .countdown)
        #expect(vm.player1Choice == .rock)
        #expect(vm.player2Choice == .scissors)
    }

    @Test func handleSessionUpdateOpponentDisconnectShowsAlert() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        session.opponentDisconnected = true
        vm.handleSessionUpdate()
        #expect(vm.showDisconnectAlert)
    }

    @Test func onlineNextRoundClearsAndAdvances() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 5)
        vm.gameState = .reveal
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.roundResult = .player1Wins
        vm.player1Score = 1
        vm.onlineNextRound()
        #expect(vm.player1Choice == nil)
        #expect(vm.player2Choice == nil)
        #expect(vm.roundResult == nil)
        #expect(vm.currentRound == 2)
        #expect(session.clearRoundCalled)
        #expect(vm.gameState == .onlineSelect)
    }

    @Test func onlineNextRoundTieDoesNotAdvance() {
        let (vm, _, _) = makeVM()
        vm.hostGame(bestOf: 5)
        vm.gameState = .reveal
        vm.roundResult = .tie
        let roundBefore = vm.currentRound
        vm.onlineNextRound()
        #expect(vm.currentRound == roundBefore)
    }

    @Test func onlineNextRoundMatchOverGoesToGameOver() {
        let (vm, _, _) = makeVM()
        vm.hostGame(bestOf: 3)
        vm.player1Score = 2
        vm.roundResult = .player1Wins
        vm.onlineNextRound()
        #expect(vm.gameState == .gameOver)
    }

    @Test func resetGameCleansUpSession() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        vm.resetGame()
        #expect(session.cleanupCalled)
        #expect(vm.session == nil)
        #expect(vm.gameState == .modeSelect)
    }

    @Test func guestCannotAdvanceRound() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 5)
        session.role = .guest
        vm.gameState = .reveal
        vm.roundResult = .player1Wins
        vm.player1Score = 1
        vm.onlineNextRound()
        // Guest should not advance — state unchanged
        #expect(vm.gameState == .reveal)
    }

    @Test func opponentIdForHost() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        session.role = .host
        session.gameData = OnlineGameData(
            hostId: "host-id", guestId: "guest-id", bestOf: 3,
            currentRound: 1, timestamp: 0
        )
        #expect(vm.opponentId == "guest-id")
    }

    @Test func opponentIdForGuest() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        session.role = .guest
        session.gameData = OnlineGameData(
            hostId: "host-id", guestId: "guest-id", bestOf: 3,
            currentRound: 1, timestamp: 0
        )
        #expect(vm.opponentId == "host-id")
    }

    @Test func playerNamesFromOnlineData() {
        let (vm, session, _) = makeVM()
        vm.hostGame(bestOf: 3)
        session.gameData = OnlineGameData(
            hostId: "host", guestId: "guest",
            hostName: "Alice", guestName: "Bob",
            bestOf: 3, currentRound: 1, timestamp: 0
        )
        #expect(vm.player1Name == "Alice")
        #expect(vm.player2Name == "Bob")
    }
}

// MARK: - GameViewModel Sound Tests

@MainActor
struct GameViewModelSoundTests {
    @Test func selectGesturePlaysTap() {
        let sound = MockSoundManager()
        let vm = GameViewModel(sound: sound)
        vm.startGame(bestOf: 3)
        vm.selectGesture(.rock)
        #expect(sound.tapCount == 1)
    }

    @Test func winPlaysWinSound() {
        let sound = MockSoundManager()
        let vm = GameViewModel(sound: sound)
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        #expect(sound.winCount == 1)
    }

    @Test func tiePlaysLieSound() {
        let sound = MockSoundManager()
        let vm = GameViewModel(sound: sound)
        vm.startGame(bestOf: 3)
        vm.isVsComputer = false // bypass tap battle for pure sound test
        vm.player1Choice = .rock
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(sound.tieCount == 1)
    }

    @Test func cpuWinPlaysLoseSound() {
        let sound = MockSoundManager()
        let vm = GameViewModel(sound: sound)
        vm.startGame(bestOf: 3)
        vm.player1Choice = .scissors
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .player2Wins)
        #expect(sound.loseCount == 1)
    }

    @Test func onlineHostLosingPlaysLoseSound() {
        let sound = MockSoundManager()
        let vm = GameViewModel(sound: sound)
        let session = MockGameSession()
        vm.makeSession = { session }
        vm.hostGame(bestOf: 3)
        session.role = .host
        vm.player1Choice = .scissors
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .player2Wins)
        #expect(sound.loseCount == 1)
    }
}

// MARK: - CharacterCatalog Tests

struct CharacterCatalogTests {
    @Test func defaultsHaveThreeCharacters() {
        #expect(CharacterCatalog.defaults.count == 3)
    }

    @Test func allCharactersHasTwelve() {
        #expect(CharacterCatalog.allCharacters.count == 12)
    }

    @Test func allPacksHasThree() {
        #expect(CharacterCatalog.allPacks.count == 3)
    }

    @Test func eachPackHasThreeCharacters() {
        for pack in CharacterCatalog.allPacks {
            #expect(pack.characters.count == 3)
        }
    }

    @Test func eachPackCoversAllSlots() {
        for pack in CharacterCatalog.allPacks {
            let slots = Set(pack.characters.map(\.slot))
            #expect(slots == Set(Move.allCases))
        }
    }

    @Test func defaultsAreUnlocked() {
        for character in CharacterCatalog.defaults {
            #expect(character.packId == nil)
        }
    }

    @Test func premiumCharactersHavePackId() {
        let premium = CharacterCatalog.allCharacters.filter { $0.packId != nil }
        #expect(premium.count == 9)
    }

    @Test func lookupByIdWorks() {
        let rock = CharacterCatalog.character(byId: "default.rock")
        #expect(rock != nil)
        #expect(rock?.slot == .rock)
        #expect(rock?.emoji == "\u{1FAA8}")
    }

    @Test func lookupByIdReturnsNilForInvalid() {
        #expect(CharacterCatalog.character(byId: "nonexistent") == nil)
    }

    @Test func filterBySlotReturnsCorrectCount() {
        for slot in Move.allCases {
            let chars = CharacterCatalog.characters(for: slot)
            #expect(chars.count == 4) // 1 default + 3 premium
            for char in chars {
                #expect(char.slot == slot)
            }
        }
    }

    @Test func allIdsAreUnique() {
        let ids = CharacterCatalog.allCharacters.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func allProductIdsAreUnique() {
        let productIds = CharacterCatalog.allPacks.map(\.productId)
        #expect(Set(productIds).count == productIds.count)
    }

    @Test func defaultLoadoutUsesDefaults() {
        let loadout = CharacterCatalog.defaultLoadout
        #expect(loadout.rockId == "default.rock")
        #expect(loadout.paperId == "default.paper")
        #expect(loadout.scissorsId == "default.scissors")
    }
}

// MARK: - CharacterLoadout Tests

struct CharacterLoadoutTests {
    @Test func getCharacterId() {
        let loadout = CharacterLoadout(
            rockId: "samurai.rock",
            paperId: "default.paper",
            scissorsId: "space.scissors"
        )
        #expect(loadout.characterId(for: .rock) == "samurai.rock")
        #expect(loadout.characterId(for: .paper) == "default.paper")
        #expect(loadout.characterId(for: .scissors) == "space.scissors")
    }

    @Test func setCharacterId() {
        var loadout = CharacterCatalog.defaultLoadout
        loadout.setCharacter("animals.rock", for: .rock)
        #expect(loadout.rockId == "animals.rock")
        #expect(loadout.paperId == "default.paper") // unchanged
    }

    @Test func codable() throws {
        let original = CharacterLoadout(
            rockId: "samurai.rock",
            paperId: "space.paper",
            scissorsId: "animals.scissors"
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CharacterLoadout.self, from: data)
        #expect(decoded.rockId == original.rockId)
        #expect(decoded.paperId == original.paperId)
        #expect(decoded.scissorsId == original.scissorsId)
    }
}

// MARK: - CharacterManager Tests

@MainActor
struct CharacterManagerTests {
    private func cleanManager() -> CharacterManager {
        UserDefaults.standard.removeObject(forKey: "characterLoadout")
        UserDefaults.standard.removeObject(forKey: "purchasedPacks")
        return CharacterManager()
    }

    @Test func defaultLoadoutReturnsDefaults() {
        let manager = cleanManager()
        let rock = manager.character(for: .rock)
        #expect(rock.id == "default.rock")
        let paper = manager.character(for: .paper)
        #expect(paper.id == "default.paper")
        let scissors = manager.character(for: .scissors)
        #expect(scissors.id == "default.scissors")
    }

    @Test func availableCharactersWithNoPurchases() {
        let manager = cleanManager()
        let available = manager.availableCharacters(for: .rock)
        #expect(available.count == 1) // only default
        #expect(available[0].id == "default.rock")
    }

    @Test func unlockPackExpandsAvailable() {
        let manager = cleanManager()
        manager.unlockPack("samurai")
        let available = manager.availableCharacters(for: .rock)
        #expect(available.count == 2) // default + samurai
        #expect(available.contains { $0.id == "samurai.rock" })
    }

    @Test func selectCharacterUpdatesLoadout() {
        let manager = cleanManager()
        manager.unlockPack("samurai")
        let katana = CharacterCatalog.samuraiRock
        manager.selectCharacter(katana, for: .rock)
        #expect(manager.character(for: .rock).id == "samurai.rock")
    }

    @Test func isPurchasedTracking() {
        let manager = cleanManager()
        #expect(!manager.isPurchased(packId: "space"))
        manager.unlockPack("space")
        #expect(manager.isPurchased(packId: "space"))
    }

    @Test func displayHelper() {
        let manager = cleanManager()
        let display = manager.display(for: .rock)
        #expect(display.emoji == "\u{1FAA8}")
        #expect(display.name == "Rock")
    }

    @Test func displayHelperWithCustomCharacter() {
        let manager = cleanManager()
        manager.unlockPack("samurai")
        manager.selectCharacter(CharacterCatalog.samuraiRock, for: .rock)
        let display = manager.display(for: .rock)
        #expect(display.emoji == "\u{2694}\u{FE0F}")
        #expect(display.name == "Katana")
    }
}

// MARK: - Move Character Extension Tests

struct MoveCharacterExtensionTests {
    @Test func displayWithNilManagerReturnsDefault() {
        let display = Move.rock.display(using: nil)
        #expect(display.emoji == Move.rock.emoji)
        #expect(display.name == Move.rock.name)
    }

    @Test @MainActor func displayWithManagerReturnsCharacter() {
        UserDefaults.standard.removeObject(forKey: "characterLoadout")
        UserDefaults.standard.removeObject(forKey: "purchasedPacks")
        let manager = CharacterManager()
        manager.unlockPack("samurai")
        manager.selectCharacter(CharacterCatalog.samuraiRock, for: .rock)
        let display = Move.rock.display(using: manager)
        #expect(display.emoji == "\u{2694}\u{FE0F}")
        #expect(display.name == "Katana")
    }

    @Test func characterAwareFlavorTextFallsBackWhenNil() {
        let text = Move.rock.flavorText(against: .scissors, myCharacter: nil, opponentCharacter: nil)
        #expect(text == "Rock crushes Scissors!")
    }

    @Test func characterAwareFlavorTextUsesNames() {
        let mine = CharacterCatalog.samuraiRock
        let theirs = CharacterCatalog.defaultScissors
        let text = Move.rock.flavorText(against: .scissors, myCharacter: mine, opponentCharacter: theirs)
        #expect(text == "Katana defeats Scissors!")
    }

    @Test func characterAwareFlavorTextNilForLoss() {
        let mine = CharacterCatalog.defaultScissors
        let theirs = CharacterCatalog.defaultRock
        let text = Move.scissors.flavorText(against: .rock, myCharacter: mine, opponentCharacter: theirs)
        #expect(text == nil)
    }
}

// MARK: - GameCharacter Tests

struct GameCharacterTests {
    @Test func hashable() {
        let a = CharacterCatalog.defaultRock
        let b = CharacterCatalog.defaultRock
        #expect(a == b)
        let set: Set<GameCharacter> = [a, b]
        #expect(set.count == 1)
    }

    @Test func codable() throws {
        let original = CharacterCatalog.samuraiRock
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GameCharacter.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.slot == original.slot)
        #expect(decoded.packId == original.packId)
    }
}
