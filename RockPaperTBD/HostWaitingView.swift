import SwiftUI

struct HostWaitingView: View {
    let roomCode: String
    let onCancel: () -> Void

    @State private var appeared = false
    @State private var codeScale: CGFloat = 0.5
    @State private var copied = false
    @State private var dotPulse = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Text("Room Code")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(appeared ? 1 : 0)

                Button {
                    UIPasteboard.general.string = roomCode
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        copied = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { copied = false }
                    }
                } label: {
                    VStack(spacing: 12) {
                        Text(roomCode)
                            .font(.system(size: 64, weight: .black, design: .monospaced))
                            .foregroundStyle(.white)
                            .tracking(8)

                        Text(copied ? "Copied!" : "Tap to copy")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                .buttonStyle(.plain)
                .scaleEffect(codeScale)

                Text("Share this code\nwith your friend")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
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
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))

                Spacer()

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .stroke(.white.opacity(0.3), lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                codeScale = 1.0
                appeared = true
            }
            dotPulse = true
        }
    }
}
