import SwiftUI

struct ContentView: View {
    @State private var game = GameViewModel()
    @State private var friendsManager = FriendsManager()
    @State private var pendingInviteFriendId: String?
    @State private var showInviteError = false

    var body: some View {
        ZStack {
            switch game.gameState {
            case .modeSelect:
                ModeSelectView(
                    onPassAndPlay: { game.gameState = .start },
                    onCreateGame: { bestOf in game.hostGame(bestOf: bestOf) },
                    onJoinGame: { game.gameState = .joinGame },
                    friendsManager: friendsManager,
                    onAcceptInvite: { invite in acceptInvite(invite) },
                    onInviteFriend: { friendId, bestOf in inviteFriend(friendId, bestOf: bestOf) }
                )
                .transition(.opacity)

            case .start:
                StartView(
                    onStart: { bestOf in game.startGame(bestOf: bestOf) },
                    onBack: { game.gameState = .modeSelect }
                )
                .transition(.opacity)

            case .hostWaiting:
                HostWaitingView(
                    roomCode: game.session?.roomCode ?? "",
                    onCancel: {
                        if let friendId = pendingInviteFriendId {
                            friendsManager.clearMyOutgoingInvite(to: friendId)
                            pendingInviteFriendId = nil
                        }
                        game.resetGame()
                    }
                )
                .transition(.opacity)

            case .joinGame:
                JoinGameView(
                    onJoin: { code, completion in
                        game.joinGame(code: code, completion: completion)
                    },
                    onCancel: game.resetGame
                )
                .transition(.opacity)

            case .player1Select:
                PlayerSelectView(
                    playerNumber: 1,
                    currentRound: game.currentRound,
                    player1Score: game.player1Score,
                    player2Score: game.player2Score,
                    onSelect: { move in
                        game.selectGesture(move, forPlayer: 1)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("p1select-\(game.currentRound)")

            case .transition:
                TransitionView(onReady: game.player2Ready)
                    .transition(.opacity)

            case .player2Select:
                PlayerSelectView(
                    playerNumber: 2,
                    currentRound: game.currentRound,
                    player1Score: game.player1Score,
                    player2Score: game.player2Score,
                    onSelect: { move in
                        game.selectGesture(move, forPlayer: 2)
                    }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("p2select-\(game.currentRound)")

            case .onlineSelect:
                PlayerSelectView(
                    playerNumber: game.session?.role == .host ? 1 : 2,
                    currentRound: game.currentRound,
                    player1Score: game.player1Score,
                    player2Score: game.player2Score,
                    isOnline: true,
                    onSelect: { move in game.submitOnlineMove(move) }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .id("online-select-\(game.currentRound)")

            case .onlineWaiting:
                OnlineWaitingView(
                    selectedMove: (game.session?.role == .host ? game.player1Choice : game.player2Choice) ?? .rock
                )
                .transition(.opacity)

            case .countdown:
                CountdownView(
                    onFinished: game.onCountdownFinished,
                    sound: game.sound
                )
                .transition(.opacity)

            case .reveal:
                if let p1 = game.player1Choice, let p2 = game.player2Choice,
                   let result = game.roundResult {
                    RevealView(
                        player1Choice: p1,
                        player2Choice: p2,
                        result: result,
                        player1Name: game.player1Name,
                        player2Name: game.player2Name,
                        player1Score: game.player1Score,
                        player2Score: game.player2Score,
                        currentRound: game.currentRound,
                        flavorText: game.flavorText,
                        isMatchOver: game.isMatchOver,
                        isOnlineGuest: game.isOnline && game.session?.role == .guest,
                        onNextRound: {
                            if game.isOnline {
                                game.onlineNextRound()
                            } else {
                                game.nextRound()
                            }
                        },
                        onReset: {
                            if game.isOnline {
                                game.resetGame()
                            } else {
                                game.resetToStart()
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }

            case .gameOver:
                if let winner = game.matchWinner {
                    GameOverView(
                        winner: winner,
                        player1Name: game.player1Name,
                        player2Name: game.player2Name,
                        player1Score: game.player1Score,
                        player2Score: game.player2Score,
                        totalRounds: game.currentRound,
                        opponentId: game.opponentId,
                        friendsManager: friendsManager,
                        sound: game.sound,
                        didLose: game.didLocalPlayerLose,
                        onPlayAgain: {
                            if game.isOnline {
                                game.resetGame()
                            } else {
                                game.resetToStart()
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: game.gameState)
        .alert("Opponent Disconnected", isPresented: $game.showDisconnectAlert) {
            Button("OK") {
                game.resetGame()
            }
        } message: {
            Text("Your opponent has left the game.")
        }
        .alert("Invite Expired", isPresented: $showInviteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("That game is no longer available.")
        }
        .onChange(of: game.gameState) { _, newState in
            if newState == .modeSelect {
                pendingInviteFriendId = nil
            }
        }
        .onAppear {
            friendsManager.observeFriends()
            friendsManager.observeRequests()
            friendsManager.observeInvites()
            // Eagerly load profile if name already saved
            if let name = DisplayName.saved {
                friendsManager.ensureProfile(displayName: name)
            }
        }
    }

    private func acceptInvite(_ invite: GameInvite) {
        friendsManager.clearInvite(from: invite.senderId)
        game.joinGame(code: invite.roomCode) { success, _ in
            if !success {
                showInviteError = true
            }
        }
    }

    private func inviteFriend(_ friendId: String, bestOf: Int) {
        pendingInviteFriendId = friendId
        game.hostGame(bestOf: bestOf) { [self] in
            if let code = game.session?.roomCode, !code.isEmpty {
                friendsManager.sendInvite(to: friendId, roomCode: code, bestOf: bestOf)
            }
        }
    }
}

#Preview {
    ContentView()
}
