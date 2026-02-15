import Foundation
import FirebaseDatabase

@Observable
final class FriendsManager {
    var profile: PlayerProfile?
    var friends: [FriendData] = []
    var incomingRequests: [FriendRequest] = []
    var pendingInvite: GameInvite?

    private var db: DatabaseReference { Database.database().reference() }
    private var friendsHandle: DatabaseHandle?
    private var requestsHandle: DatabaseHandle?
    private var invitesHandle: DatabaseHandle?

    private var myId: String { PlayerIdentity.id }

    init() {
        // Load cached profile so the friend code displays instantly
        if let code = ProfileCache.friendCode, let name = DisplayName.saved {
            profile = PlayerProfile(playerId: PlayerIdentity.id, displayName: name, friendCode: code, createdAt: 0)
        }
    }

    // MARK: - Profile

    func ensureProfile(displayName: String) {
        let playerRef = db.child(FirebasePath.players).child(myId)
        playerRef.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self else { return }
                if let dict = snapshot.value as? [String: Any],
                   let code = dict["friendCode"] as? String,
                   let name = dict["displayName"] as? String {
                    ProfileCache.friendCode = code
                    self.profile = PlayerProfile(
                        playerId: self.myId,
                        displayName: name,
                        friendCode: code,
                        createdAt: dict["createdAt"] as? TimeInterval ?? 0
                    )
                    // Update name if changed
                    if name != displayName {
                        playerRef.child("displayName").setValue(displayName)
                    }
                } else {
                    self.createProfile(displayName: displayName)
                }
            }
        }, withCancel: { [weak self] _ in
            // Firebase read denied — create profile directly
            DispatchQueue.main.async {
                self?.createProfile(displayName: displayName)
            }
        })
    }

    private func createProfile(displayName: String) {
        let code = FriendCode.generate()
        let indexRef = db.child(FirebasePath.friendCodeIndex).child(code)

        // Check code uniqueness
        indexRef.observeSingleEvent(of: .value, with: { [weak self] snapshot in
            DispatchQueue.main.async {
                guard let self else { return }
                if snapshot.exists() {
                    // Collision — retry
                    self.createProfile(displayName: displayName)
                    return
                }
                self.writeProfile(displayName: displayName, code: code)
            }
        }, withCancel: { [weak self] _ in
            // Firebase read denied — write anyway (code collision extremely unlikely)
            DispatchQueue.main.async {
                self?.writeProfile(displayName: displayName, code: code)
            }
        })
    }

    private func writeProfile(displayName: String, code: String) {
        let profileData: [String: Any] = [
            "displayName": displayName,
            "friendCode": code,
            "createdAt": ServerValue.timestamp()
        ]

        let updates: [String: Any] = [
            "\(FirebasePath.players)/\(myId)": profileData,
            "\(FirebasePath.friendCodeIndex)/\(code)/playerId": myId
        ]

        db.updateChildValues(updates)
        ProfileCache.friendCode = code
        profile = PlayerProfile(
            playerId: myId,
            displayName: displayName,
            friendCode: code,
            createdAt: Date().timeIntervalSince1970
        )
    }

    // MARK: - Friend Requests

    func sendFriendRequest(friendCode: String, completion: @escaping (Bool, String?) -> Void) {
        let upperCode = friendCode.uppercased()
        db.child(FirebasePath.friendCodeIndex).child(upperCode).child("playerId")
            .observeSingleEvent(of: .value, with: { [weak self] snapshot in
                DispatchQueue.main.async {
                    guard let self else { return }
                    guard let targetId = snapshot.value as? String else {
                        completion(false, "Friend code not found")
                        return
                    }
                    if targetId == self.myId {
                        completion(false, "That's your own code!")
                        return
                    }
                    if self.friends.contains(where: { $0.playerId == targetId }) {
                        completion(false, "Already friends!")
                        return
                    }
                    self.writeRequest(targetId: targetId, completion: completion)
                }
            }, withCancel: { error in
                DispatchQueue.main.async {
                    completion(false, "Unable to look up friend code")
                }
            })
    }

    func sendFriendRequestById(playerId: String) {
        guard playerId != myId else { return }
        guard !friends.contains(where: { $0.playerId == playerId }) else { return }
        writeRequest(targetId: playerId) { _, _ in }
    }

    private func writeRequest(targetId: String, completion: @escaping (Bool, String?) -> Void) {
        let requestData: [String: Any] = [
            "senderName": profile?.displayName ?? DisplayName.saved ?? "Player",
            "timestamp": ServerValue.timestamp()
        ]
        db.child(FirebasePath.friendRequests).child(targetId).child(myId).setValue(requestData) { error, _ in
            DispatchQueue.main.async {
                if let error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
        }
    }

    func acceptRequest(_ request: FriendRequest) {
        let myName = profile?.displayName ?? DisplayName.saved ?? "Player"
        let now = ServerValue.timestamp()

        let updates: [String: Any] = [
            "\(FirebasePath.friends)/\(myId)/\(request.senderId)/displayName": request.senderName,
            "\(FirebasePath.friends)/\(myId)/\(request.senderId)/addedAt": now,
            "\(FirebasePath.friends)/\(request.senderId)/\(myId)/displayName": myName,
            "\(FirebasePath.friends)/\(request.senderId)/\(myId)/addedAt": now,
            "\(FirebasePath.friendRequests)/\(myId)/\(request.senderId)": NSNull()
        ]

        db.updateChildValues(updates)
    }

    func declineRequest(_ request: FriendRequest) {
        db.child(FirebasePath.friendRequests).child(myId).child(request.senderId).removeValue()
    }

    func removeFriend(_ friend: FriendData) {
        let updates: [String: Any] = [
            "\(FirebasePath.friends)/\(myId)/\(friend.playerId)": NSNull(),
            "\(FirebasePath.friends)/\(friend.playerId)/\(myId)": NSNull()
        ]
        db.updateChildValues(updates)
    }

    // MARK: - Invites

    func sendInvite(to friendId: String, roomCode: String, bestOf: Int) {
        let inviteData: [String: Any] = [
            "roomCode": roomCode,
            "bestOf": bestOf,
            "senderName": profile?.displayName ?? DisplayName.saved ?? "Player",
            "timestamp": ServerValue.timestamp()
        ]
        let ref = db.child(FirebasePath.invites).child(friendId).child(myId)
        ref.setValue(inviteData)
        ref.onDisconnectRemoveValue()
    }

    func clearInvite(from senderId: String) {
        db.child(FirebasePath.invites).child(myId).child(senderId).removeValue()
    }

    func clearMyOutgoingInvite(to friendId: String) {
        db.child(FirebasePath.invites).child(friendId).child(myId).removeValue()
    }

    // MARK: - Observers

    func observeFriends() {
        let ref = db.child(FirebasePath.friends).child(myId)
        friendsHandle = ref.observe(.value) { [weak self] snapshot in
            let value = snapshot.value
            DispatchQueue.main.async {
                guard let self else { return }
                guard let dict = value as? [String: [String: Any]] else {
                    self.friends = []
                    return
                }
                self.friends = dict.compactMap { (key, val) in
                    guard let name = val["displayName"] as? String else { return nil }
                    return FriendData(
                        playerId: key,
                        displayName: name,
                        addedAt: val["addedAt"] as? TimeInterval ?? 0
                    )
                }.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
            }
        }
    }

    func observeRequests() {
        let ref = db.child(FirebasePath.friendRequests).child(myId)
        requestsHandle = ref.observe(.value) { [weak self] snapshot in
            let value = snapshot.value
            DispatchQueue.main.async {
                guard let self else { return }
                guard let dict = value as? [String: [String: Any]] else {
                    self.incomingRequests = []
                    return
                }
                self.incomingRequests = dict.compactMap { (key, val) in
                    guard let name = val["senderName"] as? String else { return nil }
                    return FriendRequest(
                        senderId: key,
                        senderName: name,
                        timestamp: val["timestamp"] as? TimeInterval ?? 0
                    )
                }
            }
        }
    }

    func observeInvites() {
        let ref = db.child(FirebasePath.invites).child(myId)
        invitesHandle = ref.observe(.value) { [weak self] snapshot in
            let value = snapshot.value
            DispatchQueue.main.async {
                guard let self else { return }
                guard let dict = value as? [String: [String: Any]] else {
                    self.pendingInvite = nil
                    return
                }
                var freshInvites: [GameInvite] = []
                for (key, val) in dict {
                    guard let code = val["roomCode"] as? String,
                          let name = val["senderName"] as? String else { continue }
                    let invite = GameInvite(
                        senderId: key,
                        senderName: name,
                        roomCode: code,
                        bestOf: val["bestOf"] as? Int ?? 3,
                        timestamp: val["timestamp"] as? TimeInterval ?? 0
                    )
                    if invite.isStale {
                        // Fix 4: clean up stale invites from Firebase
                        self.db.child(FirebasePath.invites).child(self.myId).child(key).removeValue()
                    } else {
                        freshInvites.append(invite)
                    }
                }
                self.pendingInvite = freshInvites.first
            }
        }
    }

    func stopObserving() {
        if let handle = friendsHandle {
            db.child(FirebasePath.friends).child(myId).removeObserver(withHandle: handle)
            friendsHandle = nil
        }
        if let handle = requestsHandle {
            db.child(FirebasePath.friendRequests).child(myId).removeObserver(withHandle: handle)
            requestsHandle = nil
        }
        if let handle = invitesHandle {
            db.child(FirebasePath.invites).child(myId).removeObserver(withHandle: handle)
            invitesHandle = nil
        }
    }
}
