import SwiftUI

struct SettingsView: View {
    let friendsManager: FriendsManager
    let onDismiss: () -> Void

    @State private var editedName: String = ""
    @State private var isSaving = false
    @State private var originalName: String = ""

    private var hasChanges: Bool {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed != originalName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Display Name
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DISPLAY NAME")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))

                            TextField("", text: $editedName, prompt: Text("Enter name").foregroundStyle(.white.opacity(0.2)))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(.white.opacity(0.2), lineWidth: 1.5)
                                        )
                                )
                                .characterLimit(16, text: $editedName)

                            if hasChanges {
                                Button {
                                    saveName()
                                } label: {
                                    HStack(spacing: 8) {
                                        if isSaving {
                                            ProgressView()
                                                .tint(.white)
                                                .scaleEffect(0.8)
                                        }
                                        Text("Save")
                                            .font(.system(size: 16, weight: .bold, design: .rounded))
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
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
                                .disabled(isSaving)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }

                        // Friend Code (read-only)
                        if let code = friendsManager.profile?.friendCode {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("FRIEND CODE")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.4))

                                CopyableCodeView(code: code)
                            }
                        }

                    }
                    .padding(24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { onDismiss() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
        .onAppear {
            let name = DisplayName.saved ?? ""
            editedName = name
            originalName = name
        }
    }

    private func saveName() {
        let trimmed = editedName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, trimmed != originalName else { return }
        isSaving = true
        friendsManager.updateDisplayName(trimmed)
        originalName = trimmed
        isSaving = false
    }
}
