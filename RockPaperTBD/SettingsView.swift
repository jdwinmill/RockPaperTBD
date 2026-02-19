import SwiftUI

struct SettingsView: View {
    let friendsManager: FriendsManager
    let soundManager: SoundManager
    let statsManager: StatsManager
    let characterManager: CharacterManager
    let onDismiss: () -> Void
    let onDeleteAccount: () -> Void

    @State private var editedName: String = ""
    @State private var isSaving = false
    @State private var originalName: String = ""
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showPrivacyPolicy = false

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

                        // Sound & Haptics
                        VStack(alignment: .leading, spacing: 12) {
                            Text("SOUND & HAPTICS")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))

                            VStack(spacing: 0) {
                                Toggle(isOn: Bindable(soundManager).soundEnabled) {
                                    Label("Sound Effects", systemImage: "speaker.wave.2.fill")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .tint(Theme.friendGreen)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)

                                Divider().background(.white.opacity(0.1))

                                Toggle(isOn: Bindable(soundManager).hapticsEnabled) {
                                    Label("Haptics", systemImage: "iphone.radiowaves.left.and.right")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                .tint(Theme.friendGreen)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.white.opacity(0.1))
                            )
                        }

                        // Legal
                        VStack(alignment: .leading, spacing: 12) {
                            Text("LEGAL")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.4))

                            Button {
                                showPrivacyPolicy = true
                            } label: {
                                HStack {
                                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                                        .font(.system(size: 16, weight: .medium, design: .rounded))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white.opacity(0.4))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.white.opacity(0.1))
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        // Danger Zone
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DANGER ZONE")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundStyle(.red.opacity(0.6))

                            Button {
                                showDeleteConfirm = true
                            } label: {
                                HStack(spacing: 8) {
                                    if isDeleting {
                                        ProgressView()
                                            .tint(.white)
                                            .scaleEffect(0.8)
                                    }
                                    Text("Delete All My Data")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(.red.opacity(0.8))
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(isDeleting)

                            Text("Permanently removes your profile, friends, stats, and purchases from our servers. This cannot be undone.")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
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
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .alert("Delete All Data?", isPresented: $showDeleteConfirm) {
                Button("Delete Everything", role: .destructive) {
                    performDeletion()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your profile, friends, stats, and character data. This cannot be undone.")
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

    private func performDeletion() {
        isDeleting = true

        friendsManager.deleteAllData { _ in
            statsManager.deleteStats()
            characterManager.resetAll()

            // Clear all local identity data
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: StorageKey.devicePlayerId)
            defaults.removeObject(forKey: StorageKey.playerDisplayName)
            defaults.removeObject(forKey: StorageKey.cachedFriendCode)
            defaults.removeObject(forKey: "soundEnabled")
            defaults.removeObject(forKey: "hapticsEnabled")

            isDeleting = false
            onDeleteAccount()
        }
    }
}

// MARK: - Privacy Policy

private struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

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
                    Text(privacyText)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(24)
                }
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private var privacyText: String {
        """
        Last updated: February 2025

        Rock Paper TBD ("the App") is developed by Outpost AI Labs. Your privacy is important to us.

        INFORMATION WE COLLECT

        The App stores the following data to provide online multiplayer and social features:

        - Device Identifier: A randomly generated UUID stored on your device. This is not tied to your Apple ID or any personal information.
        - Display Name: A name you choose, used to identify you to friends and opponents.
        - Friend Code: A randomly generated code that lets other players add you as a friend.
        - Friends List: The list of players you have added as friends.
        - Game Statistics: Your win/loss record for the leaderboard.

        HOW WE STORE YOUR DATA

        All online data is stored in Firebase Realtime Database, a service provided by Google. Data is associated only with your random device identifier, not with your name, email, or Apple ID.

        Character loadout preferences and purchased pack records are stored locally on your device using UserDefaults.

        DATA SHARING

        We do not sell, share, or transfer your data to third parties. Your display name and friend code are visible to other players only when you share your friend code or play an online match.

        DATA DELETION

        You can delete all of your data at any time from Settings > Delete All My Data. This permanently removes your profile, friends, statistics, and all associated data from our servers and your device.

        CHILDREN'S PRIVACY

        The App does not knowingly collect personal information from children under 13. The device identifier is randomly generated and not linked to any personal information.

        CHANGES TO THIS POLICY

        We may update this privacy policy from time to time. Continued use of the App constitutes acceptance of any changes.

        CONTACT

        If you have questions about this privacy policy, please contact us at support@outpostailabs.com.
        """
    }
}
