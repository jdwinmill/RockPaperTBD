# CLAUDE.md - RockPaperTBD

## Project
SwiftUI iOS game - Rock Paper Scissors. Pass-and-play on a single device.

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
- `SoundManager` uses a single persistent `AVAudioEngine` with pre-generated PCM buffers
- Haptics via UIKit feedback generators
- Confetti via `Canvas` + `TimelineView` (not individual SwiftUI views)
- `Theme.swift` caches all `Color(hex:)` values as static constants
- `Color(hex:)` extension lives in `CountdownView.swift`

## Key Conventions
- The gesture enum is called `Move` (not `Gesture` - conflicts with SwiftUI's `Gesture` protocol)
- Build setting: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (all types are implicitly @MainActor)
- Portrait locked via `AppDelegate`, dark mode enforced, status bar hidden
- 3 gestures: Rock, Paper, Scissors (classic RPS)
- Best of X mode: `startGame(bestOf:)` takes Int (0 = endless, 3/5/7 for match play)

## File Map
| File | Purpose |
|------|---------|
| `Gesture.swift` | `Move` enum, `RoundResult`, `GameState` |
| `GameViewModel.swift` | State machine, scoring, best-of logic |
| `ContentView.swift` | Main router with animated transitions |
| `PlayerSelectView.swift` | Gesture selection (3-across HStack) |
| `CountdownView.swift` | 3-2-1-THROW animation + `Color(hex:)` extension |
| `RevealView.swift` | Results display + `ConfettiOverlay` |
| `TransitionView.swift` | Tap-to-continue screen + `StartView` (title + best-of picker) |
| `GameOverView.swift` | Match winner screen with confetti |
| `SoundManager.swift` | AVAudioEngine tone generation + UIKit haptics |
| `Theme.swift` | Cached Color constants |
| `AppDelegate.swift` | Portrait orientation lock |

## Status
Phase 2 in progress. See `spec.md` for full details and future phase ideas.
