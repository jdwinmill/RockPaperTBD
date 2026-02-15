import Foundation
import FirebaseDatabase

@Observable
final class StatsManager {
    var leaderboard: [PlayerStats] = []
    var isLoading = false

    private var db: DatabaseReference { Database.database().reference() }
    private var myId: String { PlayerIdentity.id }

    func recordWin() {
        db.child(FirebasePath.stats).child(myId).child("wins")
            .setValue(ServerValue.increment(1 as NSNumber))
    }

    func recordLoss() {
        db.child(FirebasePath.stats).child(myId).child("losses")
            .setValue(ServerValue.increment(1 as NSNumber))
    }

    func fetchLeaderboard(friends: [FriendData]) {
        isLoading = true
        let ids = [myId] + friends.map(\.playerId)
        let nameMap = Dictionary(uniqueKeysWithValues: friends.map { ($0.playerId, $0.displayName) })
        let myName = DisplayName.saved ?? "You"

        let group = DispatchGroup()
        var results: [PlayerStats] = []
        let lock = NSLock()

        for id in ids {
            group.enter()
            db.child(FirebasePath.stats).child(id)
                .observeSingleEvent(of: .value) { snapshot in
                    let dict = snapshot.value as? [String: Any]
                    let wins = dict?["wins"] as? Int ?? 0
                    let losses = dict?["losses"] as? Int ?? 0
                    let name = id == PlayerIdentity.id ? myName : (nameMap[id] ?? "Player")
                    let stat = PlayerStats(playerId: id, displayName: name, wins: wins, losses: losses)
                    lock.lock()
                    results.append(stat)
                    lock.unlock()
                    group.leave()
                } withCancel: { _ in
                    group.leave()
                }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.leaderboard = results.sorted {
                if $0.wins != $1.wins { return $0.wins > $1.wins }
                return $0.winPercentage > $1.winPercentage
            }
            self.isLoading = false
        }
    }
}
