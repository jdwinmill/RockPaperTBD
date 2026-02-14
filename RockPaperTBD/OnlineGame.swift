import Foundation

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
    private static let key = "devicePlayerId"

    static var id: String {
        if let existing = UserDefaults.standard.string(forKey: key) {
            return existing
        }
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        return newId
    }
}

enum RoomCode {
    private static let characters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")

    static func generate() -> String {
        String((0..<4).map { _ in characters.randomElement()! })
    }
}
