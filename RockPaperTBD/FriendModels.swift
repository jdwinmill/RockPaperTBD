import Foundation

struct PlayerProfile {
    let playerId: String
    let displayName: String
    let friendCode: String
    let createdAt: TimeInterval
}

struct FriendData: Identifiable {
    var id: String { playerId }
    let playerId: String
    let displayName: String
    let addedAt: TimeInterval
}

struct FriendRequest: Identifiable {
    var id: String { senderId }
    let senderId: String
    let senderName: String
    let timestamp: TimeInterval
}

struct GameInvite: Identifiable {
    var id: String { senderId }
    let senderId: String
    let senderName: String
    let roomCode: String
    let bestOf: Int
    let timestamp: TimeInterval

    var isStale: Bool {
        Date().timeIntervalSince1970 - timestamp / 1000 > 300
    }
}

enum FriendCode {
    private static let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func generate() -> String {
        String((0..<6).map { _ in characters.randomElement()! })
    }
}

enum DisplayName {
    private static let key = "playerDisplayName"

    static var saved: String? {
        UserDefaults.standard.string(forKey: key)
    }

    static func save(_ name: String) {
        UserDefaults.standard.set(name, forKey: key)
    }
}

enum ProfileCache {
    private static let codeKey = "cachedFriendCode"

    static var friendCode: String? {
        get { UserDefaults.standard.string(forKey: codeKey) }
        set { UserDefaults.standard.set(newValue, forKey: codeKey) }
    }
}
