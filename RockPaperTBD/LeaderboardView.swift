import SwiftUI

struct LeaderboardView: View {
    let statsManager: StatsManager
    let friendsManager: FriendsManager
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if statsManager.isLoading {
                    ProgressView()
                        .tint(.white)
                } else if friendsManager.friends.isEmpty && statsManager.leaderboard.count <= 1 {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(Array(statsManager.leaderboard.enumerated()), id: \.element.id) { index, stat in
                                leaderboardRow(rank: index + 1, stat: stat)
                            }
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Ranks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            statsManager.fetchLeaderboard(friends: friendsManager.friends)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No rankings yet")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Add friends and play matches\nto see the leaderboard!")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
    }

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return Theme.winGold
        case 2: return Theme.player1Start
        case 3: return Theme.accentPink
        default: return .white.opacity(0.4)
        }
    }

    private func leaderboardRow(rank: Int, stat: PlayerStats) -> some View {
        let isMe = stat.playerId == PlayerIdentity.id

        return HStack(spacing: 16) {
            Text("#\(rank)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(rankColor(for: rank))
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(isMe ? "\(stat.displayName) (You)" : stat.displayName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("\(stat.matchesPlayed) matches")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(stat.wins)W - \(stat.losses)L")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                if stat.matchesPlayed > 0 {
                    Text("\(Int(stat.winPercentage * 100))%")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(isMe ? 0.12 : 0.08))
        )
        .padding(.horizontal, 20)
    }
}
