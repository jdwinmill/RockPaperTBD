import SwiftUI

struct DisplayNameView: View {
    let onSave: (String) -> Void

    @State private var name: String = ""
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

                Text("What's your name?")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .opacity(appeared ? 1 : 0)

                Text("Visible to your friends")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .opacity(appeared ? 1 : 0)

                TextField("", text: $name, prompt: Text("Enter name").foregroundStyle(.white.opacity(0.2)))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 40)
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
                    .characterLimit(16, text: $name)

                Spacer()

                Button {
                    let trimmed = name.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    DisplayName.save(trimmed)
                    onSave(trimmed)
                } label: {
                    Text("Continue")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.friendGreen, Theme.friendGreenEnd],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: Theme.friendGreen.opacity(0.4), radius: 12)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)
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
}
