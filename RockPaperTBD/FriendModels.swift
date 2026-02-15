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

struct PlayerStats: Identifiable {
    var id: String { playerId }
    let playerId: String
    let displayName: String
    let wins: Int
    let losses: Int

    var matchesPlayed: Int { wins + losses }
    var winPercentage: Double {
        matchesPlayed == 0 ? 0 : Double(wins) / Double(matchesPlayed)
    }
}

enum FriendCode {
    static func generate() -> String {
        CodeCharset.generate(length: 6)
    }
}

enum DisplayName {
    static var saved: String? {
        UserDefaults.standard.string(forKey: StorageKey.playerDisplayName)
    }

    static func save(_ name: String) {
        UserDefaults.standard.set(name, forKey: StorageKey.playerDisplayName)
    }
}

enum ProfileCache {
    static var friendCode: String? {
        get { UserDefaults.standard.string(forKey: StorageKey.cachedFriendCode) }
        set { UserDefaults.standard.set(newValue, forKey: StorageKey.cachedFriendCode) }
    }
}
