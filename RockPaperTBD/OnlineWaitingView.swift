import SwiftUI

struct OnlineWaitingView: View {
    let selectedMove: Move
    var characterManager: CharacterManager?

    @State private var pulseScale: CGFloat = 1.0
    @State private var appeared = false

    private var display: (emoji: String, name: String, imageName: String?) {
        selectedMove.display(using: characterManager)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.transitionStart, Theme.transitionMid, Theme.transitionEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                CharacterDisplayView(imageName: display.imageName, emoji: display.emoji, size: 100)
                    .scaleEffect(pulseScale)

                Text(display.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                PulsingDotsView()

                Text("Waiting for opponent...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: 80)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.1
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
