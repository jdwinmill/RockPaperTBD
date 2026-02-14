//
//  RockPaperTBDTests.swift
//  RockPaperTBDTests
//
//  Created by Jacob Winmill on 2/11/26.
//

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
    @Test func initialState() {
        let vm = GameViewModel()
        #expect(vm.gameState == .modeSelect)
        #expect(vm.player1Score == 0)
        #expect(vm.player2Score == 0)
        #expect(vm.currentRound == 1)
        #expect(vm.session == nil)
        #expect(!vm.isOnline)
    }

    @Test func startGameSetsState() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 5)
        #expect(vm.bestOf == 5)
        #expect(vm.gameState == .player1Select)
    }

    @Test func winsNeededCalculation() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        #expect(vm.winsNeeded == 2)

        vm.startGame(bestOf: 5)
        #expect(vm.winsNeeded == 3)

        vm.startGame(bestOf: 7)
        #expect(vm.winsNeeded == 4)
    }

    @Test func endlessModeWinsNeeded() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 0)
        #expect(vm.winsNeeded == Int.max)
        #expect(!vm.isMatchOver)
    }

    @Test func player1SelectSetsChoice() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.selectGesture(.rock, forPlayer: 1)
        #expect(vm.player1Choice == .rock)
        #expect(vm.gameState == .transition)
    }

    @Test func player2SelectSetsChoice() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.selectGesture(.rock, forPlayer: 1)
        vm.player2Ready()
        #expect(vm.gameState == .player2Select)
        vm.selectGesture(.scissors, forPlayer: 2)
        #expect(vm.player2Choice == .scissors)
        #expect(vm.gameState == .countdown)
    }

    @Test func countdownFinishedDeterminesWinner() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.selectGesture(.rock, forPlayer: 1)
        vm.player2Ready()
        vm.selectGesture(.scissors, forPlayer: 2)
        vm.onCountdownFinished()
        #expect(vm.roundResult == .player1Wins)
        #expect(vm.player1Score == 1)
        #expect(vm.gameState == .reveal)
    }

    @Test func tieDoesNotAdvanceRound() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .tie)
        let roundBefore = vm.currentRound
        vm.nextRound()
        #expect(vm.currentRound == roundBefore) // tie = same round
    }

    @Test func winAdvancesRound() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        let roundBefore = vm.currentRound
        vm.nextRound()
        #expect(vm.currentRound == roundBefore + 1)
    }

    @Test func matchOverDetected() {
        let vm = GameViewModel()
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
        let vm = GameViewModel()
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
        let vm = GameViewModel()
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
        let vm = GameViewModel()
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
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .scissors
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.roundResult == .player2Wins)
        #expect(vm.player2Score == 1)
        #expect(vm.player1Score == 0)
    }

    @Test func flavorTextSetOnWin() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .scissors
        vm.onCountdownFinished()
        #expect(vm.flavorText != nil)
    }

    @Test func flavorTextNilOnTie() {
        let vm = GameViewModel()
        vm.startGame(bestOf: 3)
        vm.player1Choice = .rock
        vm.player2Choice = .rock
        vm.onCountdownFinished()
        #expect(vm.flavorText == nil)
    }
}
