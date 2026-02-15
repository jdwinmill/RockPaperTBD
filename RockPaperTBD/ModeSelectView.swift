import SwiftUI

struct ModeSelectView: View {
    let onPassAndPlay: () -> Void
    let onCreateGame: (Int, TapBattleMode) -> Void
    let onJoinGame: () -> Void
    let friendsManager: FriendsManager
    let onAcceptInvite: (GameInvite) -> Void
    let onInviteFriend: (String, Int, TapBattleMode) -> Void

    @State private var appeared = false
    @State private var emojiOffset: [CGFloat] = [0, 0, 0]
    @State private var titleScale: CGFloat = 0.8
    @State private var selectedBestOf: Int = 3
    @State private var selectedBattleMode: TapBattleMode = .tiesOnly
    @State private var showFriends = false

    private let bestOfOptions = GameConfig.bestOfOptions

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                HStack(spacing: 20) {
                    Text("\u{1FAA8}")
                        .font(.system(size: 52))
                        .offset(y: emojiOffset[0])
                    Text("\u{1F4C4}")
                        .font(.system(size: 52))
                        .offset(y: emojiOffset[1])
                    Text("\u{2702}\u{FE0F}")
                        .font(.system(size: 52))
                        .offset(y: emojiOffset[2])
                }
                .onAppear {
                    for i in 0..<3 {
                        withAnimation(
                            .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.15)
                        ) {
                            emojiOffset[i] = -16
                        }
                    }
                }

                Text("Rock Paper")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(titleScale)

                Text("[TBD]")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.player2Start, Theme.player2End, Theme.accentPink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(titleScale)

                Spacer()

                Button {
                    onPassAndPlay()
                } label: {
                    Text("Pass & Play")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.player1Start, Theme.player1End],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Theme.player1Start.opacity(0.4), radius: 12)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                onlineDivider
                    .opacity(appeared ? 1 : 0)

                HStack(spacing: 8) {
                    ForEach(bestOfOptions, id: \.value) { option in
                        Button {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedBestOf = option.value
                            }
                        } label: {
                            Text(option.label)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(selectedBestOf == option.value ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedBestOf == option.value ? .white : .white.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appeared ? 1 : 0)

                // Tap Battle mode selector
                HStack(spacing: 8) {
                    ForEach([(TapBattleMode.tiesOnly, "Ties Only"), (.always, "Always")], id: \.0.rawValue) { mode, label in
                        Button {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedBattleMode = mode
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                Text(label)
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(selectedBattleMode == mode ? .black : .white.opacity(0.7))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedBattleMode == mode ? Theme.battleAccent : .white.opacity(0.15))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appeared ? 1 : 0)

                Button {
                    onCreateGame(selectedBestOf, selectedBattleMode)
                } label: {
                    Text("Create Game")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accentPurple, Theme.accentPink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Theme.accentPurple.opacity(0.4), radius: 12)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                HStack(spacing: 24) {
                    Button {
                        onJoinGame()
                    } label: {
                        Text("Join Game")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .buttonStyle(.plain)

                    Button {
                        showFriends = true
                    } label: {
                        HStack(spacing: 6) {
                            Text("Friends")
                                .font(.system(size: 18, weight: .medium, design: .rounded))
                                .foregroundStyle(Theme.friendGreen)
                            if !friendsManager.incomingRequests.isEmpty {
                                Circle()
                                    .fill(Theme.friendBadge)
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
                .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: 60)
            }

            // Invite banner
            if let invite = friendsManager.pendingInvite {
                VStack {
                    inviteBanner(invite)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: friendsManager.pendingInvite?.id)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
                titleScale = 1.0
            }
        }
        .sheet(isPresented: $showFriends) {
            FriendsListView(
                friendsManager: friendsManager,
                onInvite: { friendId in
                    onInviteFriend(friendId, selectedBestOf, selectedBattleMode)
                },
                onDismiss: { showFriends = false }
            )
        }
    }

    private var onlineDivider: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.white.opacity(0.2))
            Text("ONLINE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(.horizontal, 40)
    }

    private func inviteBanner(_ invite: GameInvite) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(invite.senderName) invited you!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Best of \(invite.bestOf == 0 ? "Endless" : "\(invite.bestOf)")")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Button {
                onAcceptInvite(invite)
            } label: {
                Text("Join")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Theme.friendGreen))
            }
            .buttonStyle(.plain)

            Button {
                friendsManager.clearInvite(from: invite.senderId)
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.5))
                    .font(.system(size: 14, weight: .bold))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Theme.friendGreen.opacity(0.4), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 60)
    }
}
