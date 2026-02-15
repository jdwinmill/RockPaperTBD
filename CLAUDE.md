# CLAUDE.md - RockPaperTBD

## Project
SwiftUI iOS game - Rock Paper Scissors. Pass-and-play on a single device + online 2-player via Firebase Realtime Database.

## Build & Run
```bash
xcodebuild -scheme RockPaperTBD -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```
- No iPhone 16 simulator available - always use **iPhone 17 Pro**
- Target: iOS 26.2, Swift 5
- Uses `fileSystemSynchronizedGroups` - new files added to `RockPaperTBD/` are auto-included in the build

## Architecture
- **Pure SwiftUI** (no SpriteKit)
- `@Observable` `GameViewModel` drives a state machine (`GameState` enum)
- `ContentView` is a ZStack router switching on `GameState`
- Protocol-based DI: `GameSessionProtocol` and `SoundPlayable` (in `Protocols.swift`) allow test doubles
- `GameViewModel` uses `any GameSessionProtocol` / `any SoundPlayable` + `makeSession` factory closure
- `SoundManager` uses a single persistent `AVAudioEngine` with pre-generated PCM buffers; conforms to `SoundPlayable`
- Haptics via UIKit feedback generators
- Confetti via `Canvas` + `TimelineView` (in `SharedComponents.swift`, not individual SwiftUI views)
- `SharedComponents.swift` also contains `PulsingDotsView`, `CopyableCodeView`, `CharacterLimitModifier`
- `FirebasePaths.swift` centralizes all RTDB path constants (`FirebasePath` enum)
- `Theme.swift` caches all `Color(hex:)` values as static constants
- `Color(hex:)` extension lives in `CountdownView.swift`
- **Online multiplayer** via Firebase RTDB (`GameSession` class, conforms to `GameSessionProtocol`)
- No Firebase Auth — device UUID in UserDefaults (`PlayerIdentity`)
- Room code matchmaking (4-char codes, `/games/{code}` in RTDB)
- **Friends system** via Firebase RTDB (`FriendsManager` class) — mutual friendships, friend requests, game invites
- Friend codes: 6-char generated once per player, stored in `/players/` + `/friendCodeIndex/`

## Key Conventions
- The gesture enum is called `Move` (not `Gesture` - conflicts with SwiftUI's `Gesture` protocol)
- Build setting: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (all types are implicitly @MainActor)
- Portrait locked via `AppDelegate`, dark mode enforced, status bar hidden
- 3 gestures: Rock, Paper, Scissors (classic RPS)
- `GameConfig.bestOfOptions` defines best-of choices (3, 5, 7, Endless=0)
- Best of X mode: `startGame(bestOf:)` takes Int (0 = endless, 3/5/7 for match play)
- Online mode: `hostGame(bestOf:onCreated:)` / `joinGame(code:completion:)` / `submitOnlineMove(_:)` / `onlineNextRound()`
- `GameSession` manages all Firebase RTDB interaction; `onUpdate` callback drives ViewModel state transitions
- Host controls round advancement (clears moves in Firebase); guest transitions via observer
- Friends: `FriendsManager` is separate from `GameSession` (persistent social layer vs. ephemeral game session)
- `DisplayName` helper caches player name in UserDefaults; `FriendCode` generates 6-char codes from same charset as `RoomCode`
- Use `FirebasePath` constants for RTDB paths (never hardcode path strings)

## File Map
| File | Purpose |
|------|---------|
| `Gesture.swift` | `Move` enum, `RoundResult`, `GameState`, `PlayerRole`, `GameConfig` |
| `GameViewModel.swift` | State machine, scoring, best-of, local + online methods (protocol-based DI) |
| `ContentView.swift` | Main router with animated transitions |
| `Protocols.swift` | `GameSessionProtocol` + `SoundPlayable` — abstractions for testability |
| `SharedComponents.swift` | Reusable UI: `PulsingDotsView`, `CopyableCodeView`, `CharacterLimitModifier`, `ConfettiParticle`, `ConfettiOverlay` |
| `FirebasePaths.swift` | `FirebasePath` enum — centralized RTDB path constants |
| `PlayerSelectView.swift` | Gesture selection (3-across HStack), `isOnline` param |
| `CountdownView.swift` | 3-2-1-THROW animation + `Color(hex:)` extension |
| `RevealView.swift` | Results display with confetti |
| `TransitionView.swift` | Tap-to-continue screen + `StartView` (title + best-of picker) |
| `GameOverView.swift` | Match winner screen with confetti + post-game add friend |
| `SoundManager.swift` | AVAudioEngine tone generation + UIKit haptics (conforms to `SoundPlayable`) |
| `Theme.swift` | Cached Color constants (player, countdown, results, friends) |
| `AppDelegate.swift` | Portrait lock + `FirebaseApp.configure()` |
| `OnlineGame.swift` | `OnlineGameData`, `PlayerIdentity`, `RoomCode` |
| `GameSession.swift` | Firebase RTDB manager (conforms to `GameSessionProtocol`) |
| `ModeSelectView.swift` | Mode selection: Pass & Play, Create Game, Join Game, Friends + invite banner |
| `HostWaitingView.swift` | Room code display + waiting for guest |
| `JoinGameView.swift` | Room code input + join validation |
| `OnlineWaitingView.swift` | Waiting for opponent's move |
| `FriendModels.swift` | `PlayerProfile`, `FriendData`, `FriendRequest`, `GameInvite`, `FriendCode`, `DisplayName` |
| `FriendsManager.swift` | Firebase RTDB social layer (profile/friends/requests/invites) |
| `FriendsListView.swift` | Friends hub: friend code, requests, friends list, invite/remove |
| `AddFriendView.swift` | 6-char friend code input + validation |
| `DisplayNameView.swift` | One-time display name entry |

## Dependencies
- `firebase-ios-sdk` (SPM, `FirebaseDatabase` product only) — online multiplayer
- Requires `GoogleService-Info.plist` in `RockPaperTBD/` (not checked into git)

## Firebase RTDB Schema
```
/games/{code}/          — active game sessions (existing)
/players/{uuid}/        — player profiles (displayName, friendCode, createdAt)
/friendCodeIndex/{code}/ — reverse lookup (friendCode → playerId)
/friends/{uuid}/{friendUuid}/ — mutual friendships (dual-write)
/friendRequests/{targetUuid}/{senderUuid}/ — pending friend requests
/invites/{targetUuid}/{senderUuid}/ — game invites (auto-removed onDisconnect)
```

## Status
Online multiplayer + friends system implemented. See `spec.md` for full details and future phase ideas.
