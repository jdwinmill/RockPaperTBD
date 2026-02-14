import SwiftUI

struct JoinGameView: View {
    let onJoin: (String, @escaping (Bool, String?) -> Void) -> Void
    let onCancel: () -> Void

    @State private var code: String = ""
    @State private var error: String?
    @State private var isJoining = false
    @State private var appeared = false

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

                Text("Join Game")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)

                Text("Enter the room code")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                    .opacity(appeared ? 1 : 0)

                TextField("", text: $code, prompt: Text("A3K9").foregroundStyle(.white.opacity(0.2)))
                    .font(.system(size: 48, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 60)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(.white.opacity(0.2), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 40)
                    .opacity(appeared ? 1 : 0)
                    .onChange(of: code) { _, newValue in
                        if newValue.count > 4 {
                            code = String(newValue.prefix(4))
                        }
                    }

                if let error {
                    Text(error)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                Spacer()

                Button {
                    attemptJoin()
                } label: {
                    Group {
                        if isJoining {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Join")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
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
                            .shadow(color: Theme.accentPurple.opacity(0.4), radius: 12)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .disabled(code.count < 4 || isJoining)
                .opacity(code.count < 4 ? 0.5 : 1.0)
                .opacity(appeared ? 1 : 0)

                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .opacity(appeared ? 1 : 0)

                Spacer()
                    .frame(height: 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func attemptJoin() {
        guard code.count == 4 else { return }
        isJoining = true
        error = nil
        onJoin(code) { success, errorMsg in
            isJoining = false
            if !success {
                withAnimation {
                    error = errorMsg ?? "Game not found"
                }
            }
        }
    }
}
