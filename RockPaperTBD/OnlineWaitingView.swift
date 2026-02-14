import SwiftUI

struct OnlineWaitingView: View {
    let selectedMove: Move

    @State private var pulseScale: CGFloat = 1.0
    @State private var appeared = false
    @State private var dotPulse = false

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

                Text(selectedMove.emoji)
                    .font(.system(size: 100))
                    .scaleEffect(pulseScale)

                Text(selectedMove.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(.white.opacity(0.6))
                            .frame(width: 10, height: 10)
                            .scaleEffect(dotPulse ? 1.3 : 0.7)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: dotPulse
                            )
                    }
                }

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
            dotPulse = true
        }
    }
}
