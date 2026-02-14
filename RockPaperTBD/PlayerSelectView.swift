import SwiftUI

struct PlayerSelectView: View {
    let playerNumber: Int
    let currentRound: Int
    let player1Score: Int
    let player2Score: Int
    var isOnline: Bool = false
    let onSelect: (Move) -> Void

    @State private var appeared = false
    @State private var tappedMove: Move?

    private var gradientColors: [Color] {
        if playerNumber == 1 {
            return [Theme.player1Start, Theme.player1End]
        } else {
            return [Theme.player2Start, Theme.player2End]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text(isOnline ? "Your Turn" : "Player \(playerNumber)")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -20)

                Text("Choose your move")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                    .opacity(appeared ? 1 : 0)

                if playerNumber == 1 && !isOnline {
                    Text("Player 2, look away! \u{1F440}")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .opacity(appeared ? 1 : 0)
                }

                Spacer()

                HStack(spacing: 12) {
                    ForEach(Move.allCases, id: \.self) { move in
                        gestureButton(move)
                    }
                }
                .padding(.horizontal, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)

                Spacer()

                scoreBar
                    .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func gestureButton(_ move: Move) -> some View {
        Button {
            guard tappedMove == nil else { return }
            tappedMove = move
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {}
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onSelect(move)
            }
        } label: {
            VStack(spacing: 10) {
                Text(move.emoji)
                    .font(.system(size: 48))
                Text(move.name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.white.opacity(tappedMove == move ? 0.4 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(.white.opacity(0.3), lineWidth: 2)
                    )
            )
            .scaleEffect(tappedMove == move ? 0.92 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: tappedMove)
        }
        .buttonStyle(.plain)
    }

    private var scoreBar: some View {
        HStack(spacing: 0) {
            VStack(spacing: 4) {
                Text("P1")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(player1Score)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("Round")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(currentRound)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("P2")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(player2Score)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.black.opacity(0.2))
        )
        .padding(.horizontal, 24)
    }
}
