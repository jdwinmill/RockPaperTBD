import SwiftUI

struct TapBattleView: View {
    let player1Choice: Move
    let player2Choice: Move
    let player1Name: String
    let player2Name: String
    let rpsAdvantage: RoundResult
    let isHost: Bool
    let localTapCount: Int
    let battleType: BattleType
    var isVsComputer: Bool = false
    var characterManager: CharacterManager?
    let onTap: () -> Void
    let onTimerEnd: () -> Void

    @State private var timeRemaining: Double = 3.0
    @State private var timerActive = true
    @State private var waitingForOpponent = false
    @State private var flashOpacity: Double = 0
    @State private var tapScale: CGFloat = 1.0
    @State private var ripples: [TapRipple] = []
    @State private var appeared = false
    @State private var shakeOffset: CGFloat = 0
    @State private var tapPromptScale: CGFloat = 1.0
    @State private var countGlow: CGFloat = 0
    @State private var advantagePulse: CGFloat = 1.0
    @State private var timerFlash = false

    private let battleDuration: Double = 3.0

    private var intensity: Double {
        min(1.0, Double(localTapCount) / 40.0)
    }

    var body: some View {
        ZStack {
            // Animated background that heats up with taps
            battleBackground
                .ignoresSafeArea()

            // Flash overlay on tap — scales with intensity
            Color.white
                .opacity(flashOpacity)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Ripple effects
            rippleCanvas
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Edge vignette that pulses
            radialVignette
                .ignoresSafeArea()
                .allowsHitTesting(false)

            if waitingForOpponent {
                waitingView
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            } else {
                battleContent
                    .offset(x: shakeOffset)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                appeared = true
            }
            startTimer()
            startTapPromptPulse()
            startAdvantagePulse()
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    guard timerActive, !waitingForOpponent else { return }
                    if battleType == .swipe {
                        let distance = sqrt(
                            pow(value.translation.width, 2) +
                            pow(value.translation.height, 2)
                        )
                        guard distance >= 50 else { return }
                    }
                    onTap()
                    triggerTapFeedback(at: value.location)
                }
        )
    }

    // MARK: - Background

    private var battleBackground: some View {
        // Background shifts from deep red toward bright orange as taps increase
        LinearGradient(
            colors: [
                Theme.battleStart,
                Color(
                    hue: 0.03 + intensity * 0.04,
                    saturation: 0.9,
                    brightness: 0.3 + intensity * 0.4
                ),
                Theme.battleEnd.opacity(0.5 + intensity * 0.5)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeOut(duration: 0.15), value: localTapCount)
    }

    private var radialVignette: some View {
        RadialGradient(
            colors: [
                .clear,
                .clear,
                .black.opacity(0.4 - intensity * 0.2)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 500
        )
    }

    // MARK: - Battle Content

    private var battleContent: some View {
        VStack(spacing: 0) {
            // "BATTLE!" header
            Text("BATTLE!")
                .font(.system(size: 18, weight: .black, design: .rounded))
                .tracking(6)
                .foregroundStyle(Theme.battleAccent.opacity(0.7))
                .padding(.top, 50)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.5)

            // Move emojis + advantage badge
            movesHeader
                .padding(.top, 12)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : -20)

            Spacer()

            // Tap count — the hero element
            VStack(spacing: 8) {
                Text("\(localTapCount)")
                    .font(.system(size: 140, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.battleAccent, .white],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Theme.battleAccent.opacity(countGlow), radius: 30)
                    .shadow(color: Theme.battleRipple.opacity(countGlow * 0.5), radius: 60)
                    .scaleEffect(tapScale)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.12), value: localTapCount)

                Group {
                    if battleType == .swipe {
                        VStack(spacing: 4) {
                            Text("SWIPE!")
                                .font(.system(size: 42, weight: .black, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                            HStack(spacing: 16) {
                                Image(systemName: "arrow.up")
                                Image(systemName: "arrow.down")
                                Image(systemName: "arrow.left")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                        }
                    } else {
                        Text("TAP!")
                            .font(.system(size: 42, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .scaleEffect(tapPromptScale)
            }

            Spacer()

            // Opponent mystery indicator
            VStack(spacing: 6) {
                if isVsComputer {
                    Text("\u{1F916}")
                        .font(.system(size: 36))
                        .scaleEffect(appeared ? 1 : 0)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.6).delay(0.3),
                            value: appeared
                        )
                } else {
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { i in
                            Text("?")
                                .font(.system(size: 28, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white.opacity(0.25))
                                .scaleEffect(appeared ? 1 : 0)
                                .animation(
                                    .spring(response: 0.4, dampingFraction: 0.6)
                                    .delay(0.3 + Double(i) * 0.08),
                                    value: appeared
                                )
                        }
                    }
                }

                Text(isVsComputer ? "CPU" : (isHost ? player2Name : player1Name))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.bottom, 24)

            // Timer bar
            timerBar
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
        }
    }

    // MARK: - Moves Header

    private var movesHeader: some View {
        HStack(spacing: 0) {
            // Player 1 (host) side
            playerSide(
                choice: player1Choice,
                name: player1Name,
                hasAdvantage: rpsAdvantage == .player1Wins,
                isTie: rpsAdvantage == .tie,
                isLocal: isHost
            )

            // Clash indicator
            ZStack {
                Text("VS")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(width: 44)

            // Player 2 (guest) side
            playerSide(
                choice: player2Choice,
                name: player2Name,
                hasAdvantage: rpsAdvantage == .player2Wins,
                isTie: rpsAdvantage == .tie,
                isLocal: !isHost
            )
        }
        .padding(.horizontal, 20)
    }

    private func playerSide(choice: Move, name: String, hasAdvantage: Bool, isTie: Bool, isLocal: Bool) -> some View {
        let display: (emoji: String, name: String) = isLocal ? choice.display(using: characterManager) : (choice.emoji, choice.name)
        return VStack(spacing: 4) {
            Text(display.emoji)
                .font(.system(size: 40))

            Text(name)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(isLocal ? 0.9 : 0.5))
                .lineLimit(1)

            if hasAdvantage {
                Text("+10")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.battleAccent)
                    .scaleEffect(advantagePulse)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Theme.battleAccent.opacity(0.2))
                    .clipShape(Capsule())
            } else if isTie {
                Text("EVEN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.white.opacity(0.08))
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isLocal ? .white.opacity(0.1) : .white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isLocal ? .white.opacity(0.15) : .clear,
                            lineWidth: 1
                        )
                )
        )
    }

    // MARK: - Timer Bar

    private var timerBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 8)
                    .fill(.white.opacity(0.1))

                // Fill
                RoundedRectangle(cornerRadius: 8)
                    .fill(timerGradient)
                    .frame(width: geo.size.width * max(0, timeRemaining / battleDuration))
                    .animation(.linear(duration: 0.05), value: timeRemaining)
                    .shadow(color: timerRemaining < 1.0 ? .red.opacity(0.6) : .clear, radius: 8)
            }
        }
        .frame(height: 10)
        .overlay(
            // Urgency flash when low
            RoundedRectangle(cornerRadius: 8)
                .stroke(timerFlash && timerRemaining < 1.0 ? Color.red.opacity(0.5) : .clear, lineWidth: 2)
                .padding(.horizontal, 24)
        )
    }

    private var timerRemaining: Double { timeRemaining }

    private var timerGradient: LinearGradient {
        let fraction = timeRemaining / battleDuration
        if fraction < 0.33 {
            return LinearGradient(
                colors: [Color.red, Theme.battleRipple],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return LinearGradient(
            colors: [Theme.battleAccent, Theme.battleRipple],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    // MARK: - Waiting View

    private var waitingView: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("\(localTapCount)")
                .font(.system(size: 100, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.battleAccent, .white],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text(battleType == .swipe ? "swipes" : "taps")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(4)
                .textCase(.uppercase)

            Spacer()

            PulsingDotsView()

            Text("Waiting for opponent...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
                .frame(height: 80)
        }
    }

    // MARK: - Ripple Canvas

    private var rippleCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSince1970
                for ripple in ripples {
                    let age = now - ripple.timestamp
                    guard age < 0.6 else { continue }
                    let progress = age / 0.6
                    let radius = 30 + progress * 120
                    let opacity = (1.0 - progress) * (0.2 + intensity * 0.3)

                    // Outer ring
                    let ringRect = CGRect(
                        x: ripple.position.x - radius,
                        y: ripple.position.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    )
                    context.stroke(
                        Circle().path(in: ringRect),
                        with: .color(Theme.battleAccent.opacity(opacity)),
                        lineWidth: 3 * (1.0 - progress)
                    )

                    // Inner fill
                    let innerRadius = radius * 0.6
                    let innerRect = CGRect(
                        x: ripple.position.x - innerRadius,
                        y: ripple.position.y - innerRadius,
                        width: innerRadius * 2,
                        height: innerRadius * 2
                    )
                    context.fill(
                        Circle().path(in: innerRect),
                        with: .color(Theme.battleRipple.opacity(opacity * 0.15))
                    )
                }
            }
        }
    }

    // MARK: - Timer

    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if timeRemaining <= 0 {
                timer.invalidate()
                timerActive = false
                if !isVsComputer {
                    withAnimation(.spring(response: 0.3)) {
                        waitingForOpponent = true
                    }
                }
                onTimerEnd()
                return
            }
            timeRemaining -= 0.05

            // Flash timer bar red in last second
            if timeRemaining < 1.0 {
                timerFlash.toggle()
            }
        }
    }

    // MARK: - Ambient Animations

    private func startTapPromptPulse() {
        withAnimation(
            .easeInOut(duration: 0.5)
            .repeatForever(autoreverses: true)
        ) {
            tapPromptScale = 1.1
        }
    }

    private func startAdvantagePulse() {
        withAnimation(
            .easeInOut(duration: 0.8)
            .repeatForever(autoreverses: true)
        ) {
            advantagePulse = 1.15
        }
    }

    // MARK: - Tap Feedback

    private func triggerTapFeedback(at position: CGPoint) {
        // Flash — more intense as taps climb
        let flashIntensity = 0.06 + intensity * 0.1
        flashOpacity = flashIntensity
        withAnimation(.easeOut(duration: 0.12)) {
            flashOpacity = 0
        }

        // Count glow pulse
        countGlow = 0.8
        withAnimation(.easeOut(duration: 0.3)) {
            countGlow = 0.2
        }

        // Scale bounce — gets snappier at higher counts
        let bounceScale = 1.12 + intensity * 0.08
        withAnimation(.spring(response: 0.08, dampingFraction: 0.4)) {
            tapScale = bounceScale
        }
        withAnimation(.spring(response: 0.12, dampingFraction: 0.5).delay(0.04)) {
            tapScale = 1.0
        }

        // Screen shake — subtle, increases with intensity
        let shakeAmount = 2.0 + intensity * 4.0
        shakeOffset = CGFloat.random(in: -shakeAmount...shakeAmount)
        withAnimation(.spring(response: 0.08, dampingFraction: 0.3)) {
            shakeOffset = 0
        }

        // Ripple
        let ripple = TapRipple(position: position, timestamp: Date().timeIntervalSince1970)
        ripples.append(ripple)

        // Prune old ripples
        if ripples.count > 25 {
            ripples.removeFirst(ripples.count - 25)
        }
    }
}

struct TapRipple {
    let position: CGPoint
    let timestamp: TimeInterval
}
