import SwiftUI

struct TransitionView: View {
    let onReady: () -> Void

    @State private var iconRotation: Double = 0

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

                Text("🔄")
                    .font(.system(size: 80))
                    .rotationEffect(.degrees(iconRotation))
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            iconRotation = 360
                        }
                    }

                Text("Pass to\nPlayer 2")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("Make sure Player 1\nisn't looking!")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Spacer()

                Text("Tap to continue")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))

                Spacer()
                    .frame(height: 60)
            }
        }
        .onTapGesture {
            onReady()
        }
    }
}

struct StartView: View {
    let onStart: (Int) -> Void
    var onBack: (() -> Void)? = nil

    @State private var appeared = false
    @State private var emojiOffset: [CGFloat] = [0, 0, 0]
    @State private var titleScale: CGFloat = 0.8
    @State private var selectedBestOf: Int = 3

    private let bestOfOptions: [(label: String, value: Int)] = [
        ("Best of 3", 3),
        ("Best of 5", 5),
        ("Best of 7", 7),
        ("Endless", 0),
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                if let onBack {
                    HStack {
                        Button {
                            onBack()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }

                Spacer()

                HStack(spacing: 20) {
                    Text("\u{1FAA8}")
                        .font(.system(size: 52))
                        .offset(y: emojiOffset[0])
                    Text("📄")
                        .font(.system(size: 52))
                        .offset(y: emojiOffset[1])
                    Text("✂️")
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

                Text("Pass & Play")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 4)

                Spacer()

                HStack(spacing: 10) {
                    ForEach(bestOfOptions, id: \.value) { option in
                        Button {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                selectedBestOf = option.value
                            }
                        } label: {
                            Text(option.label)
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(selectedBestOf == option.value ? .black : .white.opacity(0.7))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Capsule()
                                        .fill(selectedBestOf == option.value ? .white : .white.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .opacity(appeared ? 1 : 0)

                Button {
                    onStart(selectedBestOf)
                } label: {
                    Text("Start Game")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 48)
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
                                .shadow(color: Theme.accentPurple.opacity(0.5), radius: 16)
                        )
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
                titleScale = 1.0
            }
        }
    }
}
