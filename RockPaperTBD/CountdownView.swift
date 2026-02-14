import SwiftUI

struct CountdownView: View {
    let onFinished: () -> Void
    let sound: SoundManager

    @State private var currentNumber: Int = 3
    @State private var showThrow: Bool = false
    @State private var numberScale: CGFloat = 0.8
    @State private var numberRotation: Double = 0
    @State private var circleScales: [CGFloat] = [1, 1, 1]
    @State private var circleOpacities: [Double] = [0.3, 0.2, 0.1]
    @State private var progressDots: [Bool] = [false, false, false]
    @State private var backgroundPhase: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backgroundGradient
                    .ignoresSafeArea()

                pulsingCircles(size: geo.size)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                countdownNumber
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)

                dotsIndicator
                    .position(x: geo.size.width / 2, y: geo.size.height - 80)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            startCountdown()
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .animation(.easeInOut(duration: 0.8), value: currentNumber)
    }

    private var gradientColors: [Color] {
        if showThrow {
            return [Theme.throwStart, Theme.throwMid, Theme.throwEnd]
        }
        switch currentNumber {
        case 3: return [Theme.countdown3Start, Theme.countdown3End]
        case 2: return [Theme.countdown2Start, Theme.countdown2End]
        case 1: return [Theme.countdown1Start, Theme.countdown1End]
        default: return [Theme.throwStart, Theme.throwMid]
        }
    }

    private var countdownNumber: some View {
        Text(showThrow ? "THROW!" : "\(currentNumber)")
            .font(.system(size: showThrow ? 80 : 200, weight: .black, design: .rounded))
            .minimumScaleFactor(0.6)
            .lineLimit(1)
            .foregroundStyle(.white)
            .shadow(color: .white.opacity(0.5), radius: 24)
            .drawingGroup()
            .scaleEffect(numberScale)
            .rotationEffect(.degrees(numberRotation))
            .padding(.horizontal, 20)
    }

    private func pulsingCircles(size: CGSize) -> some View {
        let center = min(size.width, size.height)
        return ZStack {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .stroke(.white.opacity(circleOpacities[i]), lineWidth: 3)
                    .frame(width: center * 0.4 * CGFloat(i + 1),
                           height: center * 0.4 * CGFloat(i + 1))
                    .scaleEffect(circleScales[i])
            }
        }
    }

    private var dotsIndicator: some View {
        HStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(progressDots[i] ? .white : .white.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .scaleEffect(progressDots[i] ? 1.3 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: progressDots[i])
            }
        }
    }

    private func startCountdown() {
        animateBeat(number: 3)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            currentNumber = 2
            animateBeat(number: 2)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            currentNumber = 1
            animateBeat(number: 1)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.95) {
            showThrow = true
            animateThrow()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.45) {
            onFinished()
        }
    }

    private func animateBeat(number: Int) {
        sound.playCountdownBeep(step: number)

        let dotIndex = 3 - number
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            progressDots[dotIndex] = true
        }

        numberScale = 0.8
        numberRotation = 0
        withAnimation(.easeOut(duration: 0.1)) {
            numberScale = 1.3
            numberRotation = Double.random(in: -6...6)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.2)) {
                numberScale = 1.0
                numberRotation = 0
            }
        }

        // Pulse circles outward
        for i in 0..<3 {
            circleScales[i] = 0.9
            withAnimation(.easeOut(duration: 0.35).delay(Double(i) * 0.05)) {
                circleScales[i] = 1.4
                circleOpacities[i] = 0.0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeIn(duration: 0.15)) {
                    circleScales[i] = 1.0
                    circleOpacities[i] = [0.3, 0.2, 0.1][i]
                }
            }
        }
    }

    private func animateThrow() {
        sound.playCountdownBeep(step: 0)

        numberScale = 0.5
        numberRotation = -10
        withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
            numberScale = 1.0
            numberRotation = 0
        }

        // Explode circles
        for i in 0..<3 {
            withAnimation(.easeOut(duration: 0.6).delay(Double(i) * 0.05)) {
                circleScales[i] = 2.5
                circleOpacities[i] = 0.0
            }
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
