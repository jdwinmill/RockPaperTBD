import SwiftUI

struct GameOverView: View {
    let winner: RoundResult
    let player1Score: Int
    let player2Score: Int
    let totalRounds: Int
    var opponentId: String? = nil
    var friendsManager: FriendsManager? = nil
    let onPlayAgain: () -> Void

    @State private var appeared = false
    @State private var trophyScale: CGFloat = 0.0
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showConfetti = false
    @State private var sentRequest = false

    private var winnerLabel: String {
        switch winner {
        case .player1Wins: return "Player 1"
        case .player2Wins: return "Player 2"
        case .tie: return ""
        }
    }

    private var gradientColors: [Color] {
        switch winner {
        case .player1Wins: return [Theme.p1WinStart, Theme.p1WinEnd]
        case .player2Wins: return [Theme.p2WinStart, Theme.p2WinEnd]
        case .tie: return [Theme.tieStart, Theme.tieEnd]
        }
    }

    private var canAddFriend: Bool {
        guard let opponentId, let fm = friendsManager else { return false }
        return !fm.friends.contains(where: { $0.playerId == opponentId }) && !sentRequest
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("🏆")
                    .font(.system(size: 100))
                    .scaleEffect(trophyScale)

                Text("\(winnerLabel)\nWins!")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.winGold)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .opacity(appeared ? 1 : 0)

                HStack(spacing: 40) {
                    VStack(spacing: 4) {
                        Text("P1")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(player1Score)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }

                    Text("–")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))

                    VStack(spacing: 4) {
                        Text("P2")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("\(player2Score)")
                            .font(.system(size: 48, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .opacity(appeared ? 1 : 0)

                Text("\(totalRounds) rounds played")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .opacity(appeared ? 1 : 0)

                Spacer()

                if canAddFriend {
                    Button {
                        guard let opponentId else { return }
                        friendsManager?.sendFriendRequestById(playerId: opponentId)
                        withAnimation { sentRequest = true }
                    } label: {
                        Text("Add Friend")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Theme.friendGreen, Theme.friendGreenEnd],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .shadow(color: Theme.friendGreen.opacity(0.4), radius: 12)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .transition(.opacity)
                }

                if sentRequest {
                    Text("Friend request sent!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.friendGreen)
                        .opacity(appeared ? 1 : 0)
                        .transition(.opacity)
                }

                Button {
                    onPlayAgain()
                } label: {
                    Text("Play Again")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(.white)
                                .shadow(color: .white.opacity(0.3), radius: 12)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()
                    .frame(height: 60)
            }

            if showConfetti {
                ConfettiOverlay(particles: confettiParticles)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture {
            // Tap-to-continue only for local games (no Add Friend button)
            if appeared && opponentId == nil {
                onPlayAgain()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                trophyScale = 1.0
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiParticles = (0..<60).map { _ in ConfettiParticle() }
                showConfetti = true
            }
        }
    }
}
