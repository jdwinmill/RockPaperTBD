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
