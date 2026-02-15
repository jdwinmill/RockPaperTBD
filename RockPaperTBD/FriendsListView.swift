import SwiftUI

struct FriendsListView: View {
    let friendsManager: FriendsManager
    let onInvite: (String) -> Void
    let onDismiss: () -> Void

    @State private var showAddFriend = false
    @State private var needsName = false
    @State private var nameText = ""

    private var hasProfile: Bool { friendsManager.profile != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if needsName {
                    nameEntryContent
                } else {
                    ScrollView {
                        VStack(spacing: 28) {
                            friendCodeSection
                            requestsSection
                            friendsSection
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { onDismiss() }
                        .foregroundStyle(.white)
                }
                if !needsName {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showAddFriend = true
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundStyle(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAddFriend) {
                ZStack {
                    LinearGradient(
                        colors: [Theme.startTop, Theme.startMid, Theme.startBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()

                    AddFriendView(
                        friendsManager: friendsManager,
                        onDismiss: { showAddFriend = false }
                    )
                }
                .presentationDetents([.medium])
            }
            .onAppear {
                if friendsManager.profile == nil {
                    if let name = DisplayName.saved {
                        friendsManager.ensureProfile(displayName: name)
                    } else {
                        needsName = true
                    }
                }
            }
        }
    }

    // MARK: - Inline Name Entry

    private var nameEntryContent: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("What's your name?")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            Text("Visible to your friends")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))

            TextField("", text: $nameText, prompt: Text("Enter name").foregroundStyle(.white.opacity(0.2)))
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
                .characterLimit(16, text: $nameText)

            Spacer()

            Button {
                let trimmed = nameText.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                DisplayName.save(trimmed)
                friendsManager.ensureProfile(displayName: trimmed)
                withAnimation { needsName = false }
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
            .disabled(nameText.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(nameText.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1.0)

            Spacer()
                .frame(height: 60)
        }
    }

    // MARK: - Friend Code

    private var friendCodeSection: some View {
        VStack(spacing: 12) {
            Text("MY FRIEND CODE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))

            if let code = friendsManager.profile?.friendCode {
                CopyableCodeView(
                    code: code,
                    font: .system(size: 40, weight: .black, design: .monospaced),
                    tracking: 6
                )
            } else {
                ProgressView()
                    .tint(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.08))
        )
        .padding(.horizontal, 20)
    }

    // MARK: - Incoming Requests

    @ViewBuilder
    private var requestsSection: some View {
        if !friendsManager.incomingRequests.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("FRIEND REQUESTS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 20)

                ForEach(friendsManager.incomingRequests) { request in
                    HStack {
                        Text(request.senderName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Spacer()

                        Button {
                            friendsManager.acceptRequest(request)
                        } label: {
                            Text("Accept")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Theme.friendGreen))
                        }
                        .buttonStyle(.plain)

                        Button {
                            friendsManager.declineRequest(request)
                        } label: {
                            Text("Decline")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.white.opacity(0.08))
                    )
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    // MARK: - Friends List

    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("FRIENDS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
                .padding(.horizontal, 20)

            if friendsManager.friends.isEmpty {
                Text("No friends yet.\nShare your code or tap + to add one!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(friendsManager.friends) { friend in
                    friendRow(friend)
                }
            }
        }
    }

    private func friendRow(_ friend: FriendData) -> some View {
        HStack {
            Text(friend.displayName)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onInvite(friend.playerId)
                onDismiss()
            } label: {
                Text("Invite")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [Theme.accentPurple, Theme.accentPink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    )
            }
            .buttonStyle(.plain)

            Button {
                friendsManager.removeFriend(friend)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.system(size: 20))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.08))
        )
        .padding(.horizontal, 20)
    }
}
