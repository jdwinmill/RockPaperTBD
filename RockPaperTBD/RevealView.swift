import SwiftUI

struct RevealView: View {
    let player1Choice: Move
    let player2Choice: Move
    let result: RoundResult
    let player1Name: String
    let player2Name: String
    let player1Score: Int
    let player2Score: Int
    let currentRound: Int
    let flavorText: String?
    let isMatchOver: Bool
    var isOnlineGuest: Bool = false
    var characterManager: CharacterManager?
    let onNextRound: () -> Void
    let onReset: () -> Void

    private var resultLabel: String {
        switch result {
        case .player1Wins: return "\(player1Name) Wins!"
        case .player2Wins: return "\(player2Name) Wins!"
        case .tie: return "It's a Tie!"
        }
    }

    @State private var revealed = false
    @State private var showResult = false
    @State private var showButtons = false
    @State private var gesture1Scale: CGFloat = 0.0
    @State private var gesture2Scale: CGFloat = 0.0
    @State private var gesture1Rotation: Double = -180
    @State private var gesture2Rotation: Double = 180
    @State private var confettiParticles: [ConfettiParticle] = []
    @State private var showConfetti = false

    private var backgroundColor: [Color] {
        switch result {
        case .player1Wins:
            return [Theme.p1WinStart, Theme.p1WinEnd]
        case .player2Wins:
            return [Theme.p2WinStart, Theme.p2WinEnd]
        case .tie:
            return [Theme.tieStart, Theme.tieEnd]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: backgroundColor, startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                gestureRevealSection

                resultLabelView
                    .padding(.top, 8)

                if let flavorText {
                    Text(flavorText)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .opacity(showResult ? 1 : 0)
                }

                scoreSection
                    .padding(.top, 8)

                Spacer()

                buttonSection
                    .padding(.bottom, 40)
            }

            if showConfetti {
                ConfettiOverlay(particles: confettiParticles)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
        .onTapGesture {
            if showButtons && !isOnlineGuest {
                onNextRound()
            }
        }
        .onAppear {
            animateReveal()
        }
    }

    private var p1Display: (emoji: String, name: String, imageName: String?) {
        player1Choice.display(using: characterManager)
    }

    private var gestureRevealSection: some View {
        HStack(spacing: 24) {
            VStack(spacing: 12) {
                Text(player1Name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)

                CharacterDisplayView(imageName: p1Display.imageName, emoji: p1Display.emoji, size: 80)
                    .scaleEffect(gesture1Scale)
                    .rotationEffect(.degrees(gesture1Rotation))

                Text(p1Display.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(result == .player1Wins ? Theme.winGold.opacity(0.25) : .white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(result == .player1Wins ? Theme.winGold : .clear, lineWidth: 3)
                    )
            )

            Text("VS")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            VStack(spacing: 12) {
                Text(player2Name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)

                CharacterDisplayView(imageName: nil, emoji: player2Choice.emoji, size: 80)
                    .scaleEffect(gesture2Scale)
                    .rotationEffect(.degrees(gesture2Rotation))

                Text(player2Choice.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(result == .player2Wins ? Theme.winGold.opacity(0.25) : .white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(result == .player2Wins ? Theme.winGold : .clear, lineWidth: 3)
                    )
            )
        }
        .padding(.horizontal, 24)
    }

    private var resultLabelView: some View {
        Text(resultLabel)
            .font(.system(size: 40, weight: .black, design: .rounded))
            .foregroundStyle(result == .tie ? .white : Theme.winGold)
            .shadow(color: .black.opacity(0.3), radius: 4)
            .opacity(showResult ? 1 : 0)
            .scaleEffect(showResult ? 1.0 : 0.5)
    }

    private var scoreSection: some View {
        HStack(spacing: 40) {
            VStack(spacing: 4) {
                Text(player1Name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                Text("\(player1Score)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text("Round")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(currentRound)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 4) {
                Text(player2Name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                Text("\(player2Score)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
        }
        .opacity(showResult ? 1 : 0)
    }

    private var buttonSection: some View {
        VStack(spacing: 16) {
            if isOnlineGuest && !isMatchOver {
                Text("Waiting for host...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.vertical, 18)
            } else {
                Button {
                    onNextRound()
                } label: {
                    Text(isMatchOver ? "Match Over!" : result == .tie ? "Rematch!" : "Next Round")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
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
            }

            Button {
                onReset()
            } label: {
                Text("New Game")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 40)
        .opacity(showButtons ? 1 : 0)
        .offset(y: showButtons ? 0 : 20)
    }

    private func animateReveal() {
        // Spin in gestures
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.05)) {
            gesture1Scale = 1.0
            gesture1Rotation = 0
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) {
            gesture2Scale = 1.0
            gesture2Rotation = 0
        }

        // Show result
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                showResult = true
            }
        }

        // Confetti for winner
        if result != .tie {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                confettiParticles = (0..<50).map { _ in ConfettiParticle() }
                showConfetti = true
            }
        }

        // Show buttons
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                showButtons = true
            }
        }
    }
}
