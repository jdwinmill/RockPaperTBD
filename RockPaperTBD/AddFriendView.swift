import SwiftUI

struct AddFriendView: View {
    let friendsManager: FriendsManager
    let onDismiss: () -> Void

    @State private var code: String = ""
    @State private var error: String?
    @State private var isSending = false
    @State private var success = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Add Friend")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Enter their friend code")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            TextField("", text: $code, prompt: Text("X7K2M9").foregroundStyle(.white.opacity(0.2)))
                .font(.system(size: 36, weight: .black, design: .monospaced))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.characters)
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
                .padding(.horizontal, 20)
                .characterLimit(6, text: $code)

            if let error {
                Text(error)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            if success {
                Text("Friend request sent!")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.friendGreen)
                    .transition(.opacity)
            }

            Button {
                sendRequest()
            } label: {
                Group {
                    if isSending {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Send Request")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Theme.friendGreen, Theme.friendGreenEnd],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .disabled(code.count < 6 || isSending || success)
            .opacity(code.count < 6 || success ? 0.5 : 1.0)

            Button {
                onDismiss()
            } label: {
                Text("Cancel")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 24)
    }

    private func sendRequest() {
        guard code.count == 6 else { return }
        isSending = true
        error = nil
        friendsManager.sendFriendRequest(friendCode: code) { ok, errorMsg in
            isSending = false
            if ok {
                withAnimation { success = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    onDismiss()
                }
            } else {
                withAnimation { error = errorMsg ?? "Something went wrong" }
            }
        }
    }
}
