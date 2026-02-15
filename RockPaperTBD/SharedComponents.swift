import SwiftUI

// MARK: - PulsingDotsView

struct PulsingDotsView: View {
    @State private var dotPulse = false

    var body: some View {
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
        .onAppear { dotPulse = true }
    }
}

// MARK: - CopyableCodeView

struct CopyableCodeView: View {
    let code: String
    var font: Font = .system(size: 64, weight: .black, design: .monospaced)
    var tracking: CGFloat = 8

    @State private var copied = false

    var body: some View {
        Button {
            UIPasteboard.general.string = code
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                copied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { copied = false }
            }
        } label: {
            VStack(spacing: 12) {
                Text(code)
                    .font(font)
                    .foregroundStyle(.white)
                    .tracking(tracking)

                Text(copied ? "Copied!" : "Tap to copy")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Character Limit ViewModifier

struct CharacterLimitModifier: ViewModifier {
    let limit: Int
    @Binding var text: String

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { _, newValue in
                if newValue.count > limit {
                    text = String(newValue.prefix(limit))
                }
            }
    }
}

extension View {
    func characterLimit(_ limit: Int, text: Binding<String>) -> some View {
        modifier(CharacterLimitModifier(limit: limit, text: text))
    }
}

// MARK: - Confetti

struct ConfettiParticle {
    let x: CGFloat = CGFloat.random(in: 0...1)
    let hue: Double = Double.random(in: 0...1)
    let size: CGFloat = CGFloat.random(in: 6...12)
    let speed: CGFloat = CGFloat.random(in: 0.3...0.7)
    let delay: CGFloat = CGFloat.random(in: 0...0.5)
    let wobbleAmp: CGFloat = CGFloat.random(in: 20...60)
    let wobbleFreq: CGFloat = CGFloat.random(in: 2...5)
    let spinSpeed: CGFloat = CGFloat.random(in: 2...8)
}

struct ConfettiOverlay: View {
    let particles: [ConfettiParticle]
    let startDate = Date()

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startDate)
            Canvas { context, size in
                for particle in particles {
                    let t = max(0, CGFloat(elapsed) - particle.delay)
                    guard t > 0 else { continue }

                    let progress = t * particle.speed
                    let y = -20 + progress * (size.height + 40)
                    guard y < size.height + 20 else { continue }

                    let wobble = sin(t * particle.wobbleFreq) * particle.wobbleAmp
                    let px = size.width * particle.x + wobble
                    let rotation = Angle.degrees(Double(t * particle.spinSpeed) * 60)

                    context.translateBy(x: px, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(x: -particle.size / 2, y: -particle.size * 0.7,
                                      width: particle.size, height: particle.size * 1.4)
                    context.fill(
                        RoundedRectangle(cornerRadius: 2).path(in: rect),
                        with: .color(Color(hue: particle.hue, saturation: 0.8, brightness: 0.95))
                    )

                    context.rotate(by: -rotation)
                    context.translateBy(x: -px, y: -y)
                }
            }
        }
    }
}
