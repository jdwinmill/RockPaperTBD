import SwiftUI

struct HostWaitingView: View {
    let roomCode: String
    let onCancel: () -> Void

    @State private var appeared = false
    @State private var codeScale: CGFloat = 0.5

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

                CopyableCodeView(code: roomCode)
                    .scaleEffect(codeScale)

                Text("Share this code\nwith your friend")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                PulsingDotsView()

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
        }
    }
}
