import Foundation

enum CodeCharset {
    static let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func generate(length: Int) -> String {
        String((0..<length).map { _ in characters.randomElement()! })
    }
}

enum StorageKey {
    static let devicePlayerId = "devicePlayerId"
    static let playerDisplayName = "playerDisplayName"
    static let cachedFriendCode = "cachedFriendCode"
}

struct OnlineGameData {
    var hostId: String
    var guestId: String?
    var hostName: String?
    var guestName: String?
    var bestOf: Int
    var hostMove: String?
    var guestMove: String?
    var currentRound: Int
    var timestamp: TimeInterval

    var bothMovesSubmitted: Bool {
        hostMove != nil && guestMove != nil
    }
}

enum PlayerIdentity {
    static var id: String {
        if let existing = UserDefaults.standard.string(forKey: StorageKey.devicePlayerId) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: StorageKey.devicePlayerId)
        return newId
    }
}

enum RoomCode {
    static func generate() -> String {
        CodeCharset.generate(length: 4)
    }
}
